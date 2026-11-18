FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app
RUN apk add --no-cache git
RUN git init -b main \
    && git remote add origin git@github.com:imputnet/cobalt.git \
    && git config user.email "a@b.c" \
    && git config user.name "a" \
    && touch a && git add a && git commit -m "init" \
    && git update-ref refs/remotes/origin/main HEAD \
    && git branch --set-upstream-to=origin/main main \
    && chown -R node:node /app

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
