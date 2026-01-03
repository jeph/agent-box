# syntax=docker/dockerfile:1

# Agent Box
# - Arch Linux base image
# - Homebrew + Brewfile (Linux filtered) for userland tools
# - Chezmoi dotfiles applied during image build (and copied into the home volume on first use)

FROM archlinux:latest

# --- Base OS dependencies (pacman) ---
# Keep this minimal; Homebrew will provide most userland tools via Brewfile.linux.
RUN pacman -Syu --noconfirm --needed \
    base-devel \
    ca-certificates \
    curl \
    bash \
    file \
    git \
    less \
    gnupg \
    openssh \
    procps-ng \
    sudo \
    which \
  && pacman -Scc --noconfirm

# --- Non-root user for agent work ---
RUN groupadd -g 1000 agentbox \
  && useradd -m -u 1000 -g 1000 -s /bin/bash agentbox \
  && echo "agentbox ALL=(ALL) NOPASSWD:ALL" >"/etc/sudoers.d/agentbox" \
  && chmod 0440 "/etc/sudoers.d/agentbox" \
  && mkdir -p /workspace /home/linuxbrew \
  && chown -R agentbox:agentbox /workspace /home/linuxbrew

# --- Install Homebrew (Linuxbrew) ---
# Homebrew lives in /home/linuxbrew so it can be shared across projects.
ENV HOMEBREW_NO_ANALYTICS=1 \
  HOMEBREW_NO_AUTO_UPDATE=1 \
  PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH

USER agentbox
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
  && brew --version

# --- Install Brewfile dependencies ---
COPY --chown=agentbox:agentbox Brewfile.linux /tmp/Brewfile.linux
RUN brew bundle --file=/tmp/Brewfile.linux \
  && rm -f /tmp/Brewfile.linux \
  && brew cleanup --prune=all

# --- Apply dotfiles (chezmoi) ---
# Apply and keep the chezmoi working state so dotfiles can be updated later.
RUN chezmoi init --apply https://github.com/jeph/dotfiles

# --- Codex global AGENTS.md ---
RUN mkdir -p /home/agentbox/.codex
COPY --chown=agentbox:agentbox AGENTS.md /home/agentbox/.codex/AGENTS.md
COPY --chown=agentbox:agentbox codex.config.toml /home/agentbox/.codex/config.toml

# Run as non-root by default.
USER agentbox
WORKDIR /workspace

# --- Seed Codex auth from build secret (optional) ---
# If the build secret `codex_auth` is provided (typically your host `~/.codex/auth.json`),
# copy it into the image so Codex is already authenticated.
ARG CODEX_AUTH_SOURCE=""
RUN --mount=type=secret,id=codex_auth,required=false,uid=1000,gid=1000,mode=0400 \
  echo "codex_auth_source=${CODEX_AUTH_SOURCE}" >/dev/null; \
  rm -f /home/agentbox/.codex/auth.json; \
  if [ -s /run/secrets/codex_auth ]; then \
    install -m 0600 /run/secrets/codex_auth /home/agentbox/.codex/auth.json; \
  fi

CMD ["zsh"]
