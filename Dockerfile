FROM node:24-bookworm-slim

# ------------------------------------------------------------
# DeepSeek Harness rolling build
# GitHub Actions 每次构建传入不同 CACHE_BUST，
# 确保 @deepseek-ai/dsh@latest 会重新查询 npm registry。
# ------------------------------------------------------------

ARG CACHE_BUST=0

ENV DEBIAN_FRONTEND=noninteractive
ENV DSH_HOME=/home/node/.dsh

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# ------------------------------------------------------------
# 基础开发工具
#
# Python:
#   python3
#   pip
#   venv
#   Python headers
#
# C/C++:
#   gcc
#   g++
#   make
#   cmake
#   ninja
#   pkg-config
#   gdb
#
# 通用:
#   git
#   curl
#   jq
#   ripgrep
#   ssh
#   procps
#   less
#   tini
# ------------------------------------------------------------

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
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        gdb \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 提供更常见的 python / pip 命令
# ------------------------------------------------------------

RUN ln -sf /usr/bin/python3 /usr/local/bin/python \
    && ln -sf /usr/bin/pip3 /usr/local/bin/pip

# ------------------------------------------------------------
# uv
# 从 Astral 官方 uv Docker 镜像复制 uv / uvx 二进制
# ------------------------------------------------------------

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# ------------------------------------------------------------
# DeepSeek Harness + pnpm
# ------------------------------------------------------------

RUN echo "DSH build cache bust: ${CACHE_BUST}" \
    && npm install -g \
        pnpm@11.7.0 \
        @deepseek-ai/dsh@latest \
    && npm cache clean --force

# ------------------------------------------------------------
# DSH / workspace / 开发工具缓存目录
# ------------------------------------------------------------

RUN mkdir -p \
        /home/node/.dsh \
        /home/node/.cache \
        /home/node/.cache/uv \
        /workspace \
        /workspaces \
    && chown -R node:node \
        /home/node/.dsh \
        /home/node/.cache \
        /workspace \
        /workspaces

# ------------------------------------------------------------
# 构建阶段直接验证工具链
# 只要任意关键工具不存在，镜像构建就直接失败。
# ------------------------------------------------------------

RUN echo "===== DeepSeek Harness =====" \
    && dsh --version \
    && echo "===== Node =====" \
    && node --version \
    && npm --version \
    && pnpm --version \
    && echo "===== Python =====" \
    && python --version \
    && pip --version \
    && uv --version \
    && echo "===== C/C++ =====" \
    && gcc --version | head -1 \
    && g++ --version | head -1 \
    && make --version | head -1 \
    && cmake --version | head -1 \
    && ninja --version \
    && pkg-config --version \
    && gdb --version | head -1 \
    && echo "===== Git =====" \
    && git --version

USER node

WORKDIR /workspace

EXPOSE 3080

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["dsh", "web", "--no-open"]
