# Dev image for AI coding agents.
#
# Base: devcontainers/base ubuntu-24.04 (user `vscode`, uid 1000) — same as the
# image this replaces, so a home-directory PVC keeps working unchanged.
#
# Adds:
#   1. Chromium/Chrome system libraries + fonts — what Playwright's
#      `install-deps chromium` would install — so browsers downloaded at
#      runtime (Chrome for Testing via agent-browser, Chromium via Playwright)
#      can actually launch. Browsers themselves live in $HOME, not here.
#   2. mise at /usr/local/bin/mise — tools (node, go, kubectl, …) are
#      provisioned per-user from the mise config in $HOME, not baked in.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# --- Chromium/Chrome system libraries + fonts -------------------------------
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        # core chromium deps (from playwright install-deps)
        libasound2t64 \
        libatk-bridge2.0-0t64 \
        libatk1.0-0t64 \
        libatspi2.0-0t64 \
        libcairo2 \
        libcups2t64 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libglib2.0-0t64 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libx11-6 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxkbcommon0 \
        libxrandr2 \
        libxrender1 \
        libxtst6 \
        # full-chrome extras
        libfontconfig1 \
        libxss1 \
        xdg-utils \
        # fonts: latin + color emoji + CJK, so rendered screenshots aren't tofu
        fonts-liberation \
        fonts-noto-color-emoji \
        fonts-wqy-zenhei \
        fonts-ipafont-gothic \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# --- mise -------------------------------------------------------------------
# Pin the mise version; bump to upgrade.
ARG MISE_VERSION=2026.10.25
RUN curl -fsSL https://mise.run \
    | MISE_VERSION=${MISE_VERSION} MISE_INSTALL_PATH=/usr/local/bin/mise sh

# Shims on PATH for every shell (PVC-provisioned tools: node, go, kubectl, …).
# Hardcoded /home/vscode matches the PVC mount point of this environment.
ENV PATH=/home/vscode/.local/bin:/home/vscode/.opencode/bin:/home/vscode/.local/share/mise/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Login-shell activation (bash). For zsh, add to ~/.zshrc (lives on the PVC):
#   eval "$(mise activate zsh --shims)"
RUN printf 'eval "$(/usr/local/bin/mise activate bash --shims)"\n' > /etc/profile.d/mise.sh

CMD ["sleep", "infinity"]