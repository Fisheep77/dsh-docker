FROM node:24-bookworm-slim

ARG CACHE_BUST=0

ENV DEBIAN_FRONTEND=noninteractive
ENV DSH_HOME=/home/node/.dsh

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        less \
        openssh-client \
        procps \
        ripgrep \
        tini \
    && rm -rf /var/lib/apt/lists/*

RUN echo "DSH build cache bust: ${CACHE_BUST}" \
    && npm install -g \
        pnpm@11.7.0 \
        @deepseek-ai/dsh@latest \
    && npm cache clean --force \
    && dsh --version

RUN mkdir -p /home/node/.dsh /workspace \
    && chown -R node:node /home/node/.dsh /workspace

USER node

WORKDIR /workspace

EXPOSE 3080

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["dsh", "web", "--no-open"]
