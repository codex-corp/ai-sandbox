FROM node:20-alpine

# Base tools + locale + terminfo
RUN apk add --no-cache \
    --no-cache musl-locales ncurses-terminfo \
    bash ca-certificates tzdata \
    jq curl git coreutils findutils sed \
    bind-tools net-tools \
    musl-locales ncurses-terminfo

RUN npm i -g @openai/codex @google/gemini-cli

# Writable dirs
RUN mkdir -p /workspace /tmp/.cache /tmp/.config \
 && chown -R node:node /workspace /tmp

# UTF-8 + sane defaults
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color \
    HOME=/tmp \
    XDG_CACHE_HOME=/tmp/.cache \
    XDG_CONFIG_HOME=/tmp/.config

USER node
WORKDIR /workspace
CMD ["/bin/bash"]
