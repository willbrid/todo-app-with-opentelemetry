FROM node:20 AS base
WORKDIR /usr/local/app

FROM base AS client-base
COPY client/package.json client/yarn.lock ./
RUN --mount=type=cache,id=yarn,target=/usr/local/share/.cache/yarn yarn install
COPY client/.eslintrc.cjs client/index.html client/vite.config.js ./
COPY client/public ./public
COPY client/src ./src

FROM client-base AS client-build
RUN yarn build

FROM base AS backend-dev
COPY backend/package.json backend/yarn.lock ./
RUN yarn add @opentelemetry/api @opentelemetry/auto-instrumentations-node --production
RUN --mount=type=cache,id=yarn,target=/usr/local/share/.cache/yarn yarn install --frozen-lockfile

FROM base AS final
ENV NODE_ENV=production
COPY --from=backend-dev /usr/local/app/package.json /usr/local/app/yarn.lock ./
RUN --mount=type=cache,id=yarn,target=/usr/local/share/.cache/yarn yarn install --production --frozen-lockfile
COPY backend/src ./src
COPY --from=client-build /usr/local/app/dist ./src/static
EXPOSE 3000
ENTRYPOINT ["sh", "-c", "node --require @opentelemetry/auto-instrumentations-node/register src/index.js"]