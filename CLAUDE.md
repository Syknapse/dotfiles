# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

macOS dotfiles managed with [Dotbot](https://github.com/anishathalye/dotbot) (included as a git submodule at `dotbot/`). Running `./install` symlinks config files into `~` and runs setup scripts for Homebrew, ZSH, Node, macOS settings, and SSH.

## Installation

```bash
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
./install
```

`./install` drives Dotbot using `install.conf.yaml`, which runs in this order:

1. Auto-creates `secrets` from `secrets.example` (chmod 600) if it doesn't exist, then creates symlinks in `~` for `zshrc`, `zshenv`, `zprofile`, `gitconfig`, `gitignore`, `secrets`, and `~/.config/bat`
2. Creates `~/projects` and `~/work` directories
3. Runs `setup_homebrew.zsh` → `setup_zsh.zsh` → `setup_node.zsh` → `setup_macos.zsh` → `setup_ssh.zsh`

## Testing & Verification

```bash
./test.sh                    # lint: zsh -n + shellcheck + YAML validation (zero risk)
./test/sandbox-install.sh    # fresh-install simulation into a temp $HOME, run twice (idempotency)
./test/brewfile-drift.sh     # verify every Brewfile token still resolves upstream (network)
./verify.sh                  # smoke-test THIS machine's real state (symlinks, packages, macOS)
```

`test/sandbox-install.sh` is the highest-confidence local check: it runs the real `./install`
into a throwaway `$HOME` with a wiped env and all privileged steps dry-run'd, twice, asserting
the fresh-install result + idempotency. None of the first three touch the real machine.

Always run `./test.sh` before committing. A pre-push hook (`.githooks/pre-push`, enabled with
`git config core.hooksPath .githooks`) runs test.sh + the sandbox sim automatically; GitHub
Actions runs the same per push (`.github/workflows/ci.yml`) plus a weekly drift check.

Every setup script supports a dry-run that makes no changes:

```bash
DOTFILES_DRY_RUN=1 ./install   # preview the whole install
./setup_macos.zsh --dry-run    # …or a single script
```

## Key Files

| File | Purpose |
|------|---------|
| `install.conf.yaml` | Dotbot config — defines symlinks, directories, and shell commands |
| `zshrc` | Interactive shell: aliases, prompt, NVM, PATH, sources `~/.secrets` |
| `zshenv` | Non-interactive shell: `exists()` helper used by setup scripts |
| `zprofile` | Homebrew shellenv eval — loaded before zshrc |
| `gitconfig` | Git aliases, default branch, conditional include for `~/work/` |
| `Brewfile` | All Homebrew formulae, casks, VS Code extensions, npm globals |
| `setup_homebrew.zsh` | Installs Brew if missing, evals shellenv, runs `brew bundle` |
| `setup_zsh.zsh` | Sets Homebrew ZSH as the default shell |
| `setup_node.zsh` | Installs Node LTS via NVM, installs `trash-cli` globally |
| `setup_macos.zsh` | Applies macOS system preferences (Dock, Finder, keyboard, etc.) |
| `setup_ssh.zsh` | Generates Ed25519 SSH key if none exists |
| `secrets.example` | Template for `~/.secrets` — copy to `secrets`, fill in, never commit |
| `config/bat/config` | bat syntax mappings (zshrc/zshenv/zprofile → bash; Brewfile stays Ruby) |
| `config/work-gitconfig.example` | Template for `~/work/.gitconfig` (work git identity) |
| `test.sh` / `verify.sh` | Lint (no changes) / smoke-test this machine's real state |
| `test/sandbox-install.sh` | Fresh-install simulation in a temp `$HOME`, run twice — main confidence check |
| `test/brewfile-drift.sh` | Flags Brewfile tokens renamed/removed upstream |
| `.githooks/pre-push` | Pre-push gate: test.sh + sandbox sim (enable via `core.hooksPath`) |
| `.github/workflows/` | CI: lint + sandbox per push; Brewfile drift weekly |

## Secrets / API Keys

**Never put API keys in any tracked file.** The pattern is:

```bash
cp secrets.example secrets   # gitignored
# edit secrets with real values
./install                    # symlinks it to ~/.secrets
```

`zshrc` sources `~/.secrets` automatically on shell start.

## Adding a New Dotfile Symlink

Add to `install.conf.yaml` under `link:`:

```yaml
~/.filename: filename   # symlinks ~/.filename → .dotfiles/filename
```

Re-run `./install` to apply.

## Updating the Brewfile

```bash
brewbd   # brew bundle dump --force --describe --no-vscode
```

VSCode extensions are excluded (`HOMEBREW_BUNDLE_DUMP_NO_VSCODE=1` in `zshrc`) — they sync automatically via VSCode Settings Sync and don't belong in the Brewfile. Commit the result after running.

## Architecture Notes

- **Dotbot submodule:** `./install` runs `git submodule update --init --recursive` before invoking Dotbot — no manual submodule step needed.
- **`zshenv` vs `zshrc`:** `zshenv` loads for all shells (including non-interactive subprocesses spawned by Dotbot). The `exists()` function defined there is available to all setup scripts.
- **`zprofile`:** Loads for login shells before `zshrc`. Contains the Homebrew shellenv eval so `brew` is available before any interactive session.
- **`gitconfig` conditional include:** Repos inside `~/work/` automatically use `~/work/.gitconfig` for a different git identity. That file lives outside this repo — create it from `config/work-gitconfig.example`.
- **`HOMEBREW_CASK_OPTS="--no-quarantine"`** is exported rather than passed as a flag because `brew bundle` doesn't support `--no-quarantine` directly. It's set in two places: `zshrc` (for interactive use) and `setup_homebrew.zsh` (because that script runs as a non-interactive subprocess that doesn't source `zshrc`).
- **NVM in setup scripts:** `setup_node.zsh` sources nvm itself. The setup scripts run as non-interactive subprocesses that only source `zshenv` (not `zshrc`), so anything they need from `zshrc` (nvm, `HOMEBREW_CASK_OPTS`) must be re-declared in the script.
- **`stdin: true`** on the `shell:` commands in `install.conf.yaml` is required so interactive prompts (sudo/chsh passwords, ssh-keygen passphrase) can read from the terminal.
- **Testability seams:** every setup script honours `DOTFILES_DRY_RUN=1` (and a `--dry-run` arg) to preview without side effects, and `setup_zsh.zsh` honours `SHELLS_FILE` so tests never touch the real `/etc/shells`. `test/sandbox-install.sh` relies on both to run the real `./install` into a temp `$HOME` safely. When adding a privileged/irreversible command to a setup script, guard it with `$DRY_RUN` so the sandbox stays safe.
- **`setup_macos.zsh`** restarts Finder and Dock at the end. Some keyboard/trackpad settings require a logout to fully apply.
