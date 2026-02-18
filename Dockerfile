# syntax=docker/dockerfile:1

# Agent Box
# - Fedora Linux base image (ARM64)
# - Homebrew + Brewfile (Linux filtered) for userland tools
# - Chezmoi dotfiles applied during image build (and copied into the home volume on first use)

FROM --platform=linux/arm64 fedora:latest

# --- Base OS dependencies (dnf) ---
# Keep this minimal; Homebrew will provide most userland tools via Brewfile.linux.
RUN dnf -y upgrade --refresh \
  && dnf -y install --setopt=install_weak_deps=False \
    bash \
    ca-certificates \
    curl \
    file \
    findutils \
    gcc \
    git \
    glibc-langpack-en \
    gnupg2 \
    less \
    make \
    ncurses \
    ncurses-term \
    openssh-clients \
    patch \
    procps-ng \
    shadow-utils \
    sudo \
    tar \
    which \
  && dnf clean all

# --- Runtime entrypoint ---
# Guard against unsupported host TERM values forwarded into the container.
COPY docker-entrypoint.sh /usr/local/bin/agentbox-entrypoint
RUN chmod 0755 /usr/local/bin/agentbox-entrypoint

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
  HOMEBREW_BUNDLE_NO_LOCK=1 \
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

ENTRYPOINT ["/usr/local/bin/agentbox-entrypoint"]
CMD ["zsh"]
