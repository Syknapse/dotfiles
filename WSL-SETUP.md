# WSL Setup — Manual Replication of `./install`

This document translates everything `./install` does on macOS into
manual steps for **WSL (Ubuntu) on Windows**. It follows the exact
order of `install.conf.yaml`, adapting each step to Linux and skipping
what is macOS-only.

**Skipped entirely** (macOS-specific, no WSL equivalent needed):

- `setup_macos.zsh` — macOS `defaults` preferences, Dock stacks
  (`dockutil`), Finder/Dock restarts.
- Brewfile entries `dockutil` and `mas` (Mac App Store CLI).
- `~/Documents/Snips` directory (macOS screenshot folder).
- The git pre-push hook arming (`core.hooksPath .githooks`) — the hook
  runs the sandbox install test, which is written for macOS paths.
- macOS keychain SSH integration (`ssh-add --apple-use-keychain`,
  `UseKeychain yes`).

**Assumed starting point:** WSL2 with Ubuntu installed, running as
your normal user. Work inside the Linux filesystem (`~`), **not**
`/mnt/c` — symlinks and file permissions behave correctly only on the
Linux side.

## 1. Prerequisites

Update apt and make sure the basics are present:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget ca-certificates
```

## 2. Clone the repo

Equivalent of the macOS `git clone` + the submodule sync inside
`./install`. The `dotbot/` submodule is only needed to run Dotbot —
since these steps are manual, you can skip initialising it.

```bash
git clone git@github.com:Syknapse/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

(Use the HTTPS URL if the SSH key doesn't exist yet — step 9 creates
it.)

## 3. Create the secrets file

Replicates the first `shell` step in `install.conf.yaml`: create
`secrets` from the template if missing, enforce owner-only
permissions. Never commit this file — it is gitignored.

```bash
cd ~/.dotfiles
[ -f secrets ] || cp secrets.example secrets
chmod 600 secrets
```

Then edit `secrets` and fill in real API keys.

## 4. Adapt the shell config files for Linux

Two files reference Homebrew paths that don't exist on WSL. Make
these edits in your WSL clone before symlinking (consider keeping
them on a `wsl` branch so `main` stays macOS-accurate).

### 4.1 `zshrc` — nvm loader

Replace the two `/opt/homebrew/opt/nvm/...` loader lines (keep the
`export NVM_DIR` line above them) with the standard nvm loader:

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

The rest of `zshrc` works unchanged. Notes:

- `HOMEBREW_CASK_OPTS` and `HOMEBREW_BUNDLE_DUMP_NO_VSCODE` are inert
  on Linux — harmless to leave, fine to delete on the `wsl` branch.
- The `/Applications/Visual Studio Code.app/...` PATH entry is inert.
  On WSL the `code` command comes from Windows PATH interop once VS
  Code is installed on Windows (step 6.3).
- `alias man=batman` needs bat-extras (step 6.2). If you skip
  bat-extras, delete this alias.

### 4.2 `zprofile` — do not symlink it

Its only content is the macOS Homebrew shellenv eval
(`/opt/homebrew/bin/brew shellenv`), which would error on every login
shell. Skip it — apt-installed tools are already on `PATH`.

## 5. Symlink the dotfiles and create directories

Replicates the `link:` and `create:` sections of
`install.conf.yaml`. (Dotbot's `clean: ["~"]` step just removes dead
symlinks pointing into the repo — nothing to do on a fresh machine.)

```bash
cd ~/.dotfiles
ln -sfn "$PWD/zshrc"     ~/.zshrc
ln -sfn "$PWD/zshenv"    ~/.zshenv
ln -sfn "$PWD/gitconfig" ~/.gitconfig
ln -sfn "$PWD/gitignore" ~/.gitignore
ln -sfn "$PWD/secrets"   ~/.secrets
mkdir -p ~/.config
ln -sfn "$PWD/config/bat" ~/.config/bat
mkdir -p ~/projects ~/work
```

`~/.zprofile` is intentionally omitted (see 4.2), and
`~/Documents/Snips` is skipped (macOS screenshots).

## 6. Install packages (Brewfile equivalent)

`setup_homebrew.zsh` installs Homebrew and runs `brew bundle`. On
WSL, use apt for CLI tools and install GUI apps on the Windows side.
(Homebrew on Linux exists, but apt is simpler and standard on WSL.)

### 6.1 CLI formulae via apt

```bash
sudo apt install -y zsh git nano less bat ripgrep shellcheck httpie gh
```

Notes on individual tools:

- **bat** — Ubuntu names the binary `batcat`. Add a `bat` shim in
  `~/.local/bin` (already on `PATH` via `zshrc`), which also keeps
  `NULLCMD=bat` working:

  ```bash
  mkdir -p ~/.local/bin
  ln -sfn /usr/bin/batcat ~/.local/bin/bat
  ```

- **eza** — in apt on Ubuntu 24.04+ (`sudo apt install -y eza`). On
  older releases, add eza's official deb repo first:

  ```bash
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc |
    sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg]" \
    "http://deb.gierens.de stable main" |
    sudo tee /etc/apt/sources.list.d/gierens.list
  sudo apt update && sudo apt install -y eza
  ```

- **gh** — the apt version can lag; GitHub's own apt repo has the
  latest if you need it (see cli.github.com).
- **nvm** — installed in step 8, not via apt (the Brewfile installs
  it via brew on macOS; on Linux the official installer is standard).

### 6.2 bat-extras (`batman`, `batdiff`, …)

Not packaged in apt. Install from source into `~/.local`:

```bash
git clone --depth 1 https://github.com/eth-p/bat-extras.git \
  /tmp/bat-extras
/tmp/bat-extras/build.sh --install --prefix="$HOME/.local"
```

Or skip it and remove `alias man=batman` from `zshrc`.

### 6.3 GUI apps (Brewfile casks) — install on Windows

Casks are macOS GUI apps; their Windows equivalents install on the
Windows side. In an elevated PowerShell:

| Cask (macOS) | Windows equivalent |
| --- | --- |
| bitwarden | `winget install Bitwarden.Bitwarden` |
| bruno | `winget install Bruno.Bruno` |
| docker-desktop | `winget install Docker.DockerDesktop` |
| firefox | `winget install Mozilla.Firefox` |
| gitkraken | `winget install Axosoft.GitKraken` |
| google-chrome | `winget install Google.Chrome` |
| postman | `winget install Postman.Postman` |
| spotify | `winget install Spotify.Spotify` |
| visual-studio-code | `winget install Microsoft.VisualStudioCode` |

After installing:

- **Docker Desktop**: enable *Settings → Resources → WSL integration*
  for your Ubuntu distro — this provides the `docker` CLI inside WSL.
- **VS Code**: install the **WSL** extension, then `code .` from any
  WSL directory opens a remote WSL window. Extensions sync via
  Settings Sync (same reason they're excluded from the Brewfile).

## 7. Make zsh the default shell

Replicates `setup_zsh.zsh`. On Ubuntu, apt already registered
`/usr/bin/zsh` in `/etc/shells`, so no sudo edit is needed:

```bash
chsh -s "$(which zsh)"
```

Close and reopen the WSL terminal. You should see the alias banner
from `zshrc`. (WSL starts login shells, so `zshenv` + `zshrc` load
normally.)

## 8. Node via nvm + global npm packages

Replicates `setup_node.zsh`. Install nvm with the official installer.
`PROFILE=/dev/null` stops the installer appending duplicate loader
lines to the symlinked `~/.zshrc` — step 4.1 already added them.

```bash
NVM_URL=https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh
PROFILE=/dev/null bash -c "$(curl -fsSL $NVM_URL)"
```

Then, in a new shell (or after sourcing the loader):

```bash
nvm install --lts
npm i -g trash-cli
npm list --global --depth=0
```

## 9. SSH key

Replicates `setup_ssh.zsh`, minus the macOS keychain parts. Skip key
generation if `~/.ssh/id_ed25519` already exists.

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
EMAIL=$(git config --global user.email)
ssh-keygen -t ed25519 -C "$EMAIL" -f ~/.ssh/id_ed25519
```

Add a catch-all config block — only if `~/.ssh/config` doesn't
already have a `Host *` entry. Note there is **no** `UseKeychain`
line: that option is macOS-only and errors on Linux OpenSSH.

```bash
touch ~/.ssh/config && chmod 600 ~/.ssh/config
cat >> ~/.ssh/config <<'EOF'

Host *
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
EOF
```

Copy the public key to GitHub (<https://github.com/settings/ssh/new>):

```bash
cat ~/.ssh/id_ed25519.pub
```

**WSL note:** unlike macOS, no ssh-agent runs by default and nothing
persists across sessions. Either install the `keychain` package, or
add this to the end of `zshrc` (on the `wsl` branch):

```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
```

## 10. Optional: work git identity

The `gitconfig` conditional include works unchanged on Linux: any
repo under `~/work/` uses `~/work/.gitconfig`. Create it from the
template:

```bash
cp ~/.dotfiles/config/work-gitconfig.example ~/work/.gitconfig
# then edit ~/work/.gitconfig with your work name/email
```

## 11. Verify

The WSL equivalent of `verify.sh`'s spirit — open a **new** terminal
and check:

```bash
echo $SHELL                # /usr/bin/zsh
ls -l ~/.zshrc ~/.gitconfig ~/.secrets   # symlinks into ~/.dotfiles
git whoami                 # alias from gitconfig
node -v && npm -v          # from nvm LTS
bat --version              # via the ~/.local/bin shim
eza ~                      # aliased, detailed listing
rg --version && shellcheck --version && http --version
gh --version
trash --help               # trash-cli global npm package
docker version             # after enabling Docker Desktop WSL
ssh -T git@github.com      # after adding the key to GitHub
```

You should also see the alias banner table printed by `zshrc` at the
top of every new shell.
