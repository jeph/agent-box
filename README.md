# Agent Box

Arch Linux + Homebrew + your dotfiles, packaged as a Docker image intended for running agents in an isolated environment.

## Security / isolation model (read this)

This image is primarily a **repeatable, throwaway dev environment** and a **host OS risk reducer**. It is **not** a complete “agent sandbox”.

What it *does* try to isolate:
- Your **host OS/tooling** from installs and filesystem churn (everything happens inside the container)
- Accidental privilege escalation via the “hardened” run flags (drops Linux capabilities and enables `no-new-privileges`)

What it does *not* protect you from:
- **Data loss or exfiltration of anything you mount** into the container (especially `/workspace`)
- **Network exfiltration** (unless you run with networking disabled)
- Damage to persistent state in the **home volume** (`agent-box-home`), including `~/.codex/*` and other caches/credentials
- **Host-level impact** if you mount powerful interfaces like `/var/run/docker.sock` or run with `--privileged`

Practical guidance:
- Treat anything mounted into `/workspace` as **fully trusted / disposable**.
- Prefer the default “hardened” run. Use `agent-box-loose` only when you explicitly need it.
- If you care about exfiltration, run with `--network none` (or a restricted network) and only enable networking when needed.

## Build

```sh
cd /path/to/agent-box
docker compose build
```

Note: the official `archlinux` Docker image is `linux/amd64` only, so on Apple Silicon this will build/run under emulation (slower).
Homebrew and dotfiles are installed/applied during the image build.

## Run (default / hardened)

From the directory you want mounted into `/workspace`, run:

```sh
docker run --rm -it --init --platform linux/amd64 \
  -v agent-box-home:/home/agentbox \
  -v "$PWD":/workspace \
  -e TERM="${TERM:-xterm-256color}" \
  --cap-drop=ALL \
  --security-opt no-new-privileges \
  --pids-limit 512 \
  --memory 8g \
  --cpus 4 \
  agent-box:latest
```

This uses:
- A persistent home volume at `/home/agentbox` (`agent-box-home`)
- A bind mount of your current directory at `/workspace`

On first run, Docker copies the image’s `/home/agentbox` into the empty `agent-box-home` volume, so your dotfiles, `chezmoi` state, and `~/.codex/*` are present automatically.

### Shell aliases (optional)

Add these to your `~/.zshrc` or `~/.bashrc` so you can launch the container from any directory (mounting the current directory into `/workspace`):

```sh
alias agent-box='docker run --rm -it --init --platform linux/amd64 \
  -v agent-box-home:/home/agentbox \
  -v "$PWD":/workspace \
  -e TERM="${TERM:-xterm-256color}" \
  --cap-drop=ALL \
  --security-opt no-new-privileges \
  --pids-limit 512 \
  --memory 8g \
  --cpus 4 \
  agent-box:latest'

alias agent-box-loose='docker run --rm -it --init --platform linux/amd64 \
  -v agent-box-home:/home/agentbox \
  -v "$PWD":/workspace \
  -e TERM="${TERM:-xterm-256color}" \
  agent-box:latest'
```

Usage examples:

```sh
agent-box
agent-box zsh
agent-box-loose
agent-box-loose zsh
```

## Loose runtime (optional)

If you need a “more powerful” environment (e.g., working `sudo` inside the container), run without the hardened flags:

```sh
docker run --rm -it --init --platform linux/amd64 \
  -v agent-box-home:/home/agentbox \
  -v "$PWD":/workspace \
  -e TERM="${TERM:-xterm-256color}" \
  agent-box:latest
```

Notes:
- The default (hardened) run drops all Linux capabilities and enables `no-new-privileges`; setuid programs (like `sudo`) won’t work.
- Adjust limits/flags to fit your machine.

## Common tasks

### Codex auth

This image seeds Codex auth during build by copying your host `~/.codex/auth.json` into the image, and then into `agent-box-home` on first run.
If `agent-box-home` already existed, rebuilding won’t update it — remove the volume and run again.

```sh
docker volume rm agent-box-home
```

If you don’t want to bake host auth into the image, disable it for a build:

```sh
cd /path/to/agent-box
CODEX_AUTH_JSON=/dev/null docker compose build
```

Alternative: API key auth (no browser callback needed, no rebuild required):

```sh
printenv OPENAI_API_KEY | docker run --rm -i --platform linux/amd64 \
  -v agent-box-home:/home/agentbox \
  agent-box:latest codex login --with-api-key
```

### Refresh dotfiles

```sh
docker run --rm -it --init --platform linux/amd64 \
  -v agent-box-home:/home/agentbox \
  agent-box:latest chezmoi update
```

Tip: rebuilding the image won’t overwrite an existing home volume; to start fresh, remove `agent-box-home`.

### Update container dependencies

- Edit `Brewfile.linux`
- Rebuild:

```sh
(cd /path/to/agent-box && docker compose build --no-cache)
```

### Reset to a clean home

This deletes the persistent home volume (dotfiles, caches, history, etc.):

```sh
docker volume rm agent-box-home
```

## References

- Homebrew install docs: https://docs.brew.sh/Installation
- Homebrew official site (install command): https://brew.sh/
- Homebrew installer repository: https://github.com/Homebrew/install
- Official Arch Linux Docker image: https://hub.docker.com/_/archlinux
