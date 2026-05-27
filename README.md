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

1. Copy your secrets file: `cp secrets.example secrets` — then fill in your API keys
2. Create your work git identity: `cp config/work-gitconfig.example ~/work/.gitconfig` — then fill in your work name/email
3. Run `./install`

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

```bash
cp secrets.example secrets   # then edit with your values
```

`zshrc` automatically sources `~/.secrets` on shell start. The `secrets` file is gitignored.

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

```bash
./test.sh     # syntax-check all scripts (zero risk)
./verify.sh   # check current machine state against expected setup
```

`verify.sh` is safe to run at any time — it makes no changes, just reports what's correct or missing.

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
