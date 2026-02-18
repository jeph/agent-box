# Agent Box: Codex Global Instructions

You are running inside a **Fedora Linux** container intended for agent work.

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
- If Homebrew isn’t suitable (or you need system libraries), use Fedora packages: `sudo dnf install -y <pkg>`.
- Keep installs minimal and explain what you’re adding and why.
