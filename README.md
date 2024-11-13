# todo-app-with-opentelemetry

Une application simplifiée de type **Todo App**, dérivée d'un projet existant **getting-started-todo-app** sur Github. L'objectif principal de cette adaptation est de tester l'instrumentation d'une application web avec des technologies telles que **JavaScript**, **Node.js**, et **Nginx**.

### Code source original

Le code source original de ce projet est disponible ici : [https://github.com/docker/getting-started-todo-app](https://github.com/docker/getting-started-todo-app).

### Détails du projet

Certaines fonctionnalités ont été ajustées :
- Suppression de la base de données MySQL et activation de la base de données sqlite
- Retrait des tests unitaires
- Remplacement de Traefik par Nginx
- Fusion des parties frontend et backend en une application monolithique
- Ajout de l’auto-instrumentation pour l’application et le proxy Nginx

### Installation

Cette installation est uniquement faite sur un système linux : **Ubuntu 22.04** ou **Rocky 8.10**.

1. Cloner le dépôt

```
git clone https://github.com/willbrid/todo-app-with-instrumentation.git
```

```
cd todo-app-with-instrumentation
```

2. Créer les repertoires du volume de la base de données

```
mkdir -p $HOME/todolist/data && cd $HOME/todolist
```

3. Créer les fichiers de configuration **nginx.conf**, **nginx_otel_module.conf** et **otel-collector-config.yaml**

```
# $HOME/todolist/nginx.conf
server {
    listen 80;

    location / {
        proxy_pass http://app:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```
# $HOME/todolist/nginx_otel_module.conf
NginxModuleEnabled ON;
NginxModuleOtelSpanExporter otlp;
NginxModuleOtelExporterEndpoint collector:4317; # Changer ceci par votre url Otelcollector
NginxModuleServiceName nginx_proxy;
NginxModuleServiceNamespace nginx_proxy;
NginxModuleServiceInstanceId nginx_proxy;
NginxModuleResolveBackends ON;
NginxModuleTraceAsError ON;
```

```
# $HOME/todolist/otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
exporters:
  otlp:
    endpoint: jaeger:4317
    tls:
      insecure: true
service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [otlp]
```

4. Lancer l'application avec **docker compose**

```
docker compose up --build --watch
```

### Utilisation

- Accéder à l'interface de l'application via le lien **http://localhost**, puis ajouter, modifier ou supprimer les tâches.
- Les données d'instrumentation sont disponibles dans l'application **Jaeger** via le lien **http://localhost:16686**.