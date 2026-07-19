# WSL Quick Setup — Standalone Version

Goal: get a fresh Windows + WSL (Ubuntu) machine to the closest
equivalent of my usual mac setup with the least fuss. No dotfiles
repo, no symlinks — config files are written directly into place and
live on this machine only.

Everything below runs inside the WSL Ubuntu terminal unless marked
**Windows**. Work in the Linux home (`~`), not `/mnt/c`.

Deliberately dropped from the mac setup: Homebrew (apt instead),
Dotbot/symlinks, macOS system preferences, `dockutil`, `mas`,
bat-extras (`batman`), the bat config, `zshenv`/`zprofile` (only
needed by the repo's setup scripts and Homebrew), and the Snips
folder.

## 1. Install packages

One apt line covers the whole Brewfile CLI list:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y zsh git curl nano less bat eza ripgrep \
  shellcheck httpie gh
```

Ubuntu names the bat binary `batcat` — add a shim so `bat` works:

```bash
mkdir -p ~/.local/bin
ln -sfn /usr/bin/batcat ~/.local/bin/bat
```

If `eza` isn't found (Ubuntu older than 24.04), skip it for now or
add its deb repo later — everything else works without it.

## 2. Create the config files

### `~/.zshrc`

Adapted from the repo version: Homebrew bits removed, standard nvm
loader, `man=batman` and `brewbd` dropped, ssh-agent startup added
(WSL has no keychain).

```bash
cat > ~/.zshrc <<'EOF'
echo 'Aliases: lsf, eza, restart, trail, mkcd, pn'

# bat instead of cat for null commands
export NULLCMD=bat

# Load secrets (API keys etc.) — never commit that file
[ -f ~/.secrets ] && source ~/.secrets

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Aliases
alias lsf='ls -lAFh'
alias eza='eza -lahF --git'
alias restart='source ~/.zshrc'
alias trail='<<<${(F)path}'
alias pn='pnpm'

# Prompt (user@host, cwd, git branch, time, shell level)
setopt PROMPT_SUBST
function parse_git_branch() {
  git branch 2>/dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}
PROMPT='
%F{33}%n@%m%f %F{201}%~%f %F{113}$(parse_git_branch)%f %F{222}%*%f %L %#
'

# PATH
typeset -U path
path=($HOME/.local/bin $path)

# Make a directory and cd into it: mkcd new_project
function mkcd() {
  mkdir -p "$@" && cd "$_"
}

# Start ssh-agent if none is running (WSL has no macOS keychain)
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
EOF
```

### `~/.gitconfig`

**Identity is flipped vs the mac repo:** on a work machine the work
identity is the default. Edit the name/email before running.

```bash
cat > ~/.gitconfig <<'EOF'
[user]
 name = Your Work Name
 email = yourname@company.com
[init]
 defaultBranch = main
[alias]
 st = status
 co = checkout
 last = log -1 HEAD
 whoami = !git config user.name && git config user.email
[core]
 editor = nano
 excludesfile = ~/.gitignore
EOF
```

If you'll also do personal projects on this machine, add a personal
identity override for `~/projects/`:

```bash
cat >> ~/.gitconfig <<'EOF'
[includeIf "gitdir:~/projects/"]
 path = ~/projects/.gitconfig
EOF
```

…and put your personal `[user]` block in `~/projects/.gitconfig`.

### Global gitignore, secrets, directories

```bash
echo '.vscode' > ~/.gitignore
touch ~/.secrets && chmod 600 ~/.secrets
mkdir -p ~/projects ~/work
```

Add exports to `~/.secrets` as needed, e.g.
`export ANTHROPIC_API_KEY="..."` — `zshrc` sources it on every shell.

## 3. Make zsh the default shell

```bash
chsh -s "$(which zsh)"
```

Reopen the terminal — you should land in zsh with the custom prompt.

## 4. Node via nvm

```bash
NVM_URL=https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh
PROFILE=/dev/null bash -c "$(curl -fsSL $NVM_URL)"
```

(`PROFILE=/dev/null` stops the installer editing `~/.zshrc` — the
loader is already there.) Then in a new shell:

```bash
nvm install --lts
npm i -g trash-cli
```

## 5. SSH key + GitHub

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "$(git config --global user.email)" \
  -f ~/.ssh/id_ed25519
cat >> ~/.ssh/config <<'EOF'
Host *
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
EOF
chmod 600 ~/.ssh/config
```

Then add the public key to GitHub (work account:
<https://github.com/settings/ssh/new>) and authenticate gh:

```bash
cat ~/.ssh/id_ed25519.pub
gh auth login
```

## 6. Windows-side apps

Casks don't apply in WSL — install the GUI apps on Windows. In
PowerShell, pick what the job actually needs:

```powershell
winget install Microsoft.VisualStudioCode
winget install Docker.DockerDesktop
winget install Mozilla.Firefox
winget install Google.Chrome
winget install Bitwarden.Bitwarden
winget install Bruno.Bruno
winget install Postman.Postman
winget install Axosoft.GitKraken
winget install Spotify.Spotify
```

Then:

- **VS Code**: install the *WSL* extension; `code .` inside WSL then
  opens a remote window. Extensions/settings arrive via Settings
  Sync, same as on the mac.
- **Docker Desktop**: enable *Settings → Resources → WSL integration*
  so the `docker` CLI works inside Ubuntu.

## 7. Quick check

New terminal, then:

```bash
echo $SHELL          # /usr/bin/zsh, custom prompt visible
git whoami           # work identity
node -v && npm -v
bat --version && rg --version && gh --version
ssh -T git@github.com
```

Done — that's the working mac environment, minus the mac.
