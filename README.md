# Agent Box

Fedora Linux (ARM64) + Homebrew + your dotfiles, packaged as a Docker image intended for running agents in an isolated environment.

## Security / Isolation Model

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

This project targets `linux/arm64` so Apple Silicon can build and run natively (no Rosetta requirement).
Homebrew and dotfiles are installed/applied during the image build.

## Run

From the directory you want mounted into `/workspace`, run:

```sh
docker run --rm -it --init --platform linux/arm64 \
  -v agent-box-home:/home/agentbox \
  -v "$PWD":/workspace \
  --mount type=bind,src=/run/host-services/ssh-auth.sock,target=/run/host-services/ssh-auth.sock \
  --group-add "$(docker run --rm --platform linux/arm64 \
    --mount type=bind,src=/run/host-services/ssh-auth.sock,target=/ssh-auth.sock \
    agent-box:latest stat -c %g /ssh-auth.sock)" \
  -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
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

On first run, Docker copies the image’s `/home/agentbox` into the empty `agent-box-home` volume, so your dotfiles, `chezmoi` state, and Codex config files are present automatically.

### Shell Aliases (optional)

Add these to your `~/.zshrc` or `~/.bashrc` so you can launch the container from any directory (mounting the current directory into `/workspace`):

```sh
alias agent-box='docker run --rm -it --init --platform linux/arm64 \
  -v agent-box-home:/home/agentbox \
  -v "$PWD":/workspace \
  --mount type=bind,src=/run/host-services/ssh-auth.sock,target=/run/host-services/ssh-auth.sock \
  --group-add "$(docker run --rm --platform linux/arm64 \
    --mount type=bind,src=/run/host-services/ssh-auth.sock,target=/ssh-auth.sock \
    agent-box:latest stat -c %g /ssh-auth.sock)" \
  -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
  -e TERM="${TERM:-xterm-256color}" \
  --cap-drop=ALL \
  --security-opt no-new-privileges \
  --pids-limit 512 \
  --memory 8g \
  --cpus 4 \
  agent-box:latest'

alias agent-box-loose='docker run --rm -it --init --platform linux/arm64 \
  -v agent-box-home:/home/agentbox \
  -v "$PWD":/workspace \
  --mount type=bind,src=/run/host-services/ssh-auth.sock,target=/run/host-services/ssh-auth.sock \
  --group-add "$(docker run --rm --platform linux/arm64 \
    --mount type=bind,src=/run/host-services/ssh-auth.sock,target=/ssh-auth.sock \
    agent-box:latest stat -c %g /ssh-auth.sock)" \
  -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
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

## Loose Runtime

If you need a “more powerful” environment (e.g., working `sudo` inside the container), run without the hardened flags:

```sh
docker run --rm -it --init --platform linux/arm64 \
  -v agent-box-home:/home/agentbox \
  -v "$PWD":/workspace \
  --mount type=bind,src=/run/host-services/ssh-auth.sock,target=/run/host-services/ssh-auth.sock \
  --group-add "$(docker run --rm --platform linux/arm64 \
    --mount type=bind,src=/run/host-services/ssh-auth.sock,target=/ssh-auth.sock \
    agent-box:latest stat -c %g /ssh-auth.sock)" \
  -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
  -e TERM="${TERM:-xterm-256color}" \
  agent-box:latest
```

Notes:
- The default (hardened) run drops all Linux capabilities and enables `no-new-privileges`; setuid programs (like `sudo`) won’t work.
- Adjust limits/flags to fit your machine.

## Common Tasks

### Codex Auth

Credentials are not baked into the image. Authenticate from inside the running container, and the resulting auth state is stored in the persistent `agent-box-home` volume.

### Update Container Dependencies

- Edit `Brewfile.linux`
- Rebuild:

```sh
(cd /path/to/agent-box && docker compose build --no-cache)
```

Tip: rebuilding the image won’t overwrite an existing home volume; to start fresh, remove `agent-box-home`

### Reset Home Directory 

This deletes the persistent home volume (dotfiles, caches, history, etc.):

```sh
docker volume rm agent-box-home
```
