# .dotfiles

macOS dotfiles repo — managed with [Dotbot](https://github.com/anishathalye/dotbot).

---

## Quick Start

```bash
git clone <repo_address> ~/.dotfiles
cd ~/.dotfiles
./install
```

> **Note:** On a brand new Mac, the Homebrew installer may prompt you to install Xcode Command Line Tools — that's expected and required. The install script handles everything else automatically.
>
> **Apple Silicon only:** This repo assumes an Apple Silicon Mac — Homebrew paths are hardcoded to `/opt/homebrew` (in `zprofile`, `zshrc`, and the `setup_*.zsh` scripts). On an Intel Mac, Homebrew installs to `/usr/local`, so those paths would need adjusting.

`./install` will:
1. Create symlinks in `~` for all config files
2. Create `~/projects` and `~/work` directories
3. Install all Homebrew packages + casks from the Brewfile
4. Set Homebrew ZSH as the default shell
5. Install Node LTS via NVM
6. Apply macOS system preferences
7. Generate an SSH key (if none exists)

---

## After Cloning on a New Machine

1. Run `./install` — it auto-creates `secrets` from the template (chmod 600, gitignored) and symlinks it to `~/.secrets`
2. Add your API keys to `~/.dotfiles/secrets` (already symlinked — no re-install needed)
3. Create your work git identity: `cp config/work-gitconfig.example ~/work/.gitconfig` — then fill in your work name/email

> **Tip:** If you want your keys present from the very first shell, run `cp secrets.example secrets` and fill it in *before* `./install`. Existing secrets are never overwritten.

---

## Symlinks

Files are symlinked from `~/.dotfiles/` into your home directory via `install.conf.yaml`.  
To add a new dotfile: add an entry under `link:` in `install.conf.yaml`:
```yaml
~/.filename: filename
```
Re-run `./install` to apply.

---

## Secrets & API Keys

Private environment variables (API keys, tokens) belong in `~/.secrets` — **never in any tracked file**.

`./install` auto-creates `secrets` from `secrets.example` (with `600` permissions) if it doesn't exist, then symlinks it to `~/.secrets`. Just add your values:

```bash
$EDITOR ~/.dotfiles/secrets   # created by ./install; edit to add your keys
```

`zshrc` automatically sources `~/.secrets` on shell start. The `secrets` file is gitignored and is never overwritten when you re-run `./install`.

---

## Brewfile

The Brewfile tracks Homebrew packages and apps (but **not** VSCode extensions — those sync automatically via VSCode Settings Sync).

To regenerate it from your current machine state:

```bash
brewbd   # brew bundle dump --force --describe --no-vscode
```

The `HOMEBREW_BUNDLE_DUMP_NO_VSCODE=1` env var (set in `zshrc`) ensures VSCode extensions are excluded even if `brew bundle dump` is run directly without the alias.

Then commit and push the updated Brewfile.

---

## macOS Settings

`setup_macos.zsh` applies your system preferences (Dock, Finder, keyboard, trackpad, screenshots, etc.).

```bash
./setup_macos.zsh --dry-run   # preview what would change
./setup_macos.zsh             # apply all settings
```

---

## Testing & Verification

Four layers, fastest first — the first three make **no changes to your Mac**:

```bash
./test.sh                    # lint: zsh -n + shellcheck + YAML validation (instant)
./test/sandbox-install.sh    # simulate a fresh install into a throwaway $HOME, twice
./test/brewfile-drift.sh     # check every Brewfile package still resolves upstream (network)
./verify.sh                  # check THIS machine's real state against the expected setup
```

- **`test/sandbox-install.sh`** is the closest thing to a fresh-machine test without a fresh machine: it runs the real `./install` into a temp `$HOME` with a wiped environment and every privileged step neutralised (dry-run), **twice**, asserting both the fresh-install result and idempotency.
- **`test/brewfile-drift.sh`** catches the "a cask got renamed/removed upstream" class of failure (e.g. `docker` → `docker-desktop`) *before* install day.

### Preview the whole install

Every setup script honours a dry-run mode that makes no changes:

```bash
DOTFILES_DRY_RUN=1 ./install      # preview the entire install
./setup_macos.zsh --dry-run       # …or a single script
```

### Automated gates

```bash
git config core.hooksPath .githooks   # enable the pre-push hook (test.sh + sandbox sim)
```

GitHub Actions runs the lint + sandbox simulation on every push, and the Brewfile drift check weekly. Bypass the hook in a pinch with `git push --no-verify`.

---

## Keeping Everything Synced

After editing any dotfile: commit and push. On other machines:
```bash
git pull
./install
```

---

## Work Git Identity

`~/.gitconfig` conditionally loads `~/work/.gitconfig` for any repo inside `~/work/`. That file must be created manually (it's outside this repo since it may contain a different work identity):

```bash
cp config/work-gitconfig.example ~/work/.gitconfig
# then edit ~/work/.gitconfig with your work name and email
```

---

*Based on [dotfiles.eieio.xyz](http://dotfiles.eieio.xyz)*
