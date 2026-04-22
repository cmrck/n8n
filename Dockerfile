FROM node:24.14.1-alpine AS builder

WORKDIR /app

# Rebuild native modules for target container platform
RUN apk add --no-cache python3 make g++
COPY ./compiled /usr/local/lib/node_modules/n8n
RUN cd /usr/local/lib/node_modules/n8n && npm rebuild sqlite3 isolated-vm

FROM node:24.14.1-alpine AS runtime

ENV NODE_ENV=production
ENV SHELL=/bin/sh

WORKDIR /home/node

RUN apk add --no-cache \
    tini \
    tzdata \
    openssl \
    ca-certificates \
    libc6-compat \
    git \
    openssh \
    graphicsmagick

COPY --from=builder /usr/local/lib/node_modules/n8n /usr/local/lib/node_modules/n8n
COPY docker/images/n8n/docker-entrypoint.sh /docker-entrypoint.sh

RUN ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n \
    && mkdir -p /home/node/.n8n /home/node/custom \
    && chown -R node:node /home/node \
    && chmod +x /docker-entrypoint.sh

USER node

EXPOSE 5678

ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
