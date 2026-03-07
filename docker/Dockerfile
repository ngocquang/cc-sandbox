FROM node:20

ARG TZ=Asia/Ho_Chi_Minh
ENV TZ="$TZ"

# ============================================================
# 📦 Install development tools + firewall utilities
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    less git procps sudo fzf zsh man-db unzip gnupg2 gh \
    iptables ipset iproute2 dnsutils aggregate jq \
    nano vim curl wget python3 python3-pip \
    ripgrep fd-find openssh-client ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Setup non-root user ─────────────────────────────────────
ARG USERNAME=node

RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# ── Persist shell history ────────────────────────────────────
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

ENV DEVCONTAINER=true

# ── Copy firewall script ────────────────────────────────────
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh

# ── Create workspace & config ────────────────────────────────
RUN mkdir -p /workspace /home/node/.claude && \
    chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

# ── Install git-delta ────────────────────────────────────────
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# ── Switch to non-root user ─────────────────────────────────
USER node

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=/home/node/.local/bin:$PATH:/usr/local/share/npm-global/bin
ENV SHELL=/bin/zsh
ENV EDITOR=nano
ENV VISUAL=nano

# ── Install Claude Code (native installer) ─────────────────
# Binary goes to ~/.local/bin (persisted via volume mount in docker run)
RUN mkdir -p /home/node/.local/bin \
    && curl -fsSL https://claude.ai/install.sh | bash

ENTRYPOINT ["/bin/zsh", "-l"]
