# Agent Box: Codex Global Instructions

You are running inside an **Arch Linux** container intended for agent work.

## Useful tools already installed

- Search: `rg` (ripgrep), `fd`
- JSON: `jq`
- VCS: `git`
- Python: `uv`
- Node.js: `fnm` (Node version manager), `pnpm` (requires a Node version via `fnm`)
- Rust: `rustup`
- Dotfiles: `chezmoi`

## Installing dependencies

- You may install additional **non-malicious** dependencies if they help you complete the task.
- Prefer **Homebrew for Linux** first: `brew install <pkg>`.
- If Homebrew isn’t suitable (or you need system libraries), use Arch packages: `sudo pacman -S --needed <pkg>`.
- Keep installs minimal and explain what you’re adding and why.
