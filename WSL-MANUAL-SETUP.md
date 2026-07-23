# WSL Manual Setup

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

Work repos live in
`~/work`, `~/projects` is kept empty/reserved for any future personal
project. No personal git identity override configured for now — skip
the `includeIf` block below unless that changes.

## 0. Install WSL2 itself (Windows side, PowerShell as Admin)

### Option 1 automatic install

```powershell
wsl --install
```

Restart Windows if prompted, then launch "Ubuntu" from the Start menu
and set a Unix username/password.

### Option 2 manual install

The automatic powershell install script often fails. YOu can do the process manually.
In WSL2 (C.2026) this was the best  way to do it:

- Windows menu: Turn Windows features on or off -> activate Virtual Machine Platform & Windows Subsystem for Linux
- Restart computer
- Open terminal -> Use command prompt
- Run `wsl.exe --update` to install wsl
- Check you are using WSL2 `wsl --version`
- Check available remote distros `wsl.exe --list --online`
- Install latest Ubuntu LTS `wsl.exe --install <distro exact name>`
- Set unix user name and password
- In new shell, check correct distro installed `lsb_release -a`
- Set Ubuntu as default shell in Terminal

## 1. Install packages

Update Ubuntu and install all CLI tools:

> `-y` auto-confirms the "do you want to continue?" prompts so the whole line runs unattended.
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y zsh git curl nano less bat eza ripgrep shellcheck httpie gh
```

Ubuntu names the bat binary `batcat` — add a shim so `bat` works:

```bash
mkdir -p ~/.local/bin
ln -sfn /usr/bin/batcat ~/.local/bin/bat
```

## 2. Create the config files

### `~/.zshrc`

Adapted from the repo version: Homebrew bits removed, standard nvm
loader, `man=batman` and `brewbd` dropped, **persistent** ssh-agent
startup added (WSL has no keychain — see note below).

Run the following command to create and populate the file
```bash
cat > ~/.zshrc <<'EOF'
echo '.zshrc loaded'
echo 'Available aliases: lsf, eza, man, restart, brewbd, trail, mkcd, pn'
echo -e "┌─────────────────┬────────────────────────┬───────────────┬────────────┬───────┐"
echo -e "│ lsf -> ls -lAFh │ eza -> eza -lahF --git │ man -> batman │ pn -> pnpm │       │"
echo -e "├─────────────────┴────────────────────────┴─────┬─────────┴────────────┴───────┤"
echo -e "│ restart -> source ~/.zshrc && source ~/.zshenv │ trail -> print PATH variable │"
echo -e "├────────────────────────────────────────────────┴──────────────────────────────┤"
echo -e "│ mkcd -> make a new directory and cd into it mkcd 'new_project'                │"
echo -e "└───────────────────────────────────────────────────────────────────────────────┘"
  
# bat instead of cat for null commands
export NULLCMD=bat

# Load secrets (API keys etc.) — never commit that file
[ -f ~/.secrets ] && source ~/.secrets

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Aliases
# More detailed version of ls
alias lsf='ls -lAFh'
# Much more detailed and colorful version of ls
alias eza='eza -lahF --git'
# Restart the shell implementing changes to zsh config files
alias restart='source ~/.zshrc && source ~/.zshenv '
# A more readable way to print PATH variable
alias trail='<<<${(F)path}'
# A quicker way to type pnpm
alias pn='pnpm'

# A better version of the manual comand (just use `man <command>` as usual)
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Prompt (user@host, cwd, git branch, time, shell level)
# Prompt variables: https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
# Prompt customisation: https://www.makeuseof.com/customize-zsh-prompt-macos-terminal/
# Adding git branch: https://gist.github.com/reinvanoyen/05bcfe95ca9cb5041a4eafd29309ff29
# Legend:
# %F{<number 0-256>}<part to colorise>%f : add color
# %n : $USERNAME
# %m : short host name
# %~ : current working directory
# %L : current shell level $SHLVL
# %* : current time with seconds
# %# : shows # for sudo user and % for normal user
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

# Create a new directory and cd to it
# USAGE: mkcd 'new_project'
function mkcd() {
  mkdir -p "$@" && cd "$_"
}

# Persistent ssh-agent across terminals (WSL has no macOS keychain)
SSH_ENV="$HOME/.ssh/agent-environment"

function start_agent {
  ssh-agent -s > "${SSH_ENV}"
  chmod 600 "${SSH_ENV}"
  . "${SSH_ENV}" > /dev/null
  ssh-add ~/.ssh/id_ed25519
}

if [ -f "${SSH_ENV}" ]; then
  . "${SSH_ENV}" > /dev/null
  kill -0 "${SSH_AGENT_PID}" 2>/dev/null || start_agent
else
  start_agent
fi
EOF
```

> `kill -0 <pid>` asks the kernel directly whether that PID is alive to avoid requesting the passphrase on each new shell

> `pn='pnpm'` only works once pnpm is actually installed (see step 5
> below) — the alias does nothing on its own before that.

### `~/.gitconfig`

The work identity is the default. Edit the name/email before running.

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

If you'll also do personal projects on this machine, add a personal identity override for ~/projects/:
```bash
cat >> ~/.gitconfig <<'EOF'
[includeIf "gitdir:~/projects/"]
 path = ~/projects/.gitconfig
EOF
```
Or just copy the IncludeIf block into the main gitconfig. 
Then create a gitconfig for /projects with personal git identity

### Global gitignore, secrets, directories

Create a global gitignore file and add `.vscode` to the ignore list.
Create a secrets file. Create the work and projects directories.

```bash
echo '.vscode' > ~/.gitignore
touch ~/.secrets && chmod 600 ~/.secrets
mkdir -p ~/projects ~/work
```

## 3. Make zsh the default shell

```bash
chsh -s "$(which zsh)"
```

Reopen the terminal — you should land in zsh with the custom prompt.
If you still see bash after this, close the *whole* terminal window
(not just a tab) and reopen — WSL sometimes needs a full session
cycle to pick up the shell change. Check the shell you are using with `echo $SHELL`

## 4. Node via nvm

Fetches and installs the latest NVM release

```bash
NVM_LATEST=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_LATEST/install.sh)"
```

Or you can decide the version manually
Check [github.com/nvm-sh/nvm/releases](https://github.com/nvm-sh/nvm/releases)

```bash
NVM_URL=https://raw.githubusercontent.com/nvm-sh/nvm/<"VERSION NUMBER ex: v0.40.6">/install.sh
PROFILE=/dev/null bash -c "$(curl -fsSL $NVM_URL)"
```

(`PROFILE=/dev/null` stops the installer editing `~/.zshrc` — the
loader is already there.) Then in a new shell:

```bash
nvm install --lts
```

## 5. pnpm

Install right after Node exists, since pnpm installs via npm (which
ships bundled with Node from nvm):

```bash
npm i -g pnpm
```

## 6. SSH key + GitHub
This similar to following GitHub's SSH setup, but tailored to our case

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "$(git config --global user.email)" \
  -f ~/.ssh/id_ed25519
```

> You'll be prompted for a passphrase
> The persistent ssh-agent set up above means you only  type it once per WSL boot
> 4–6 random unrelated words rather than a short complex password 

Scoped to GitHub only 

```bash
cat >> ~/.ssh/config <<'EOF'
Host github.com
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
EOF
chmod 600 ~/.ssh/config
```

Use gh to login and authenticate

```bash
gh auth login
```
When it asks whether to upload the SSH key to your account, say yes and give it a title when prompted — suggested format: `<context>-wsl-<year>` (e.g. `ailin-wsl-2026`), so it's identifiable later if you ever need to revoke it.

> If you see "Authentication credentials saved in plain text" after auth finishes: expected on WSL, since there's normally no OS keyring/Secret Service running for gh to use instead.
> Low risk on a single-user machine — just remember to revoke the token via GitHub settings (or gh auth logout) if this machine is ever decommissioned or shared.

Or you can create the key in github.com manually before login
Copy key

```bash
cat ~/.ssh/id_ed25519.pub
```
→ paste at <https://github.com/settings/ssh/new>, and name it:

First SSH connection will show a host-key confirmation prompt
("authenticity of host github.com can't be established") — this is
expected on a first connection, not a problem. GitHub's current
Ed25519 fingerprint (cross-check before typing `yes` if you want to
be certain): `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`

```bash
ssh -T git@github.com
```

## 7. Apps to install

Use Microsoft store, oficial sites (or `winget`)
[] VS Code
[] Docker Desktop
[] Chrome
[] Firefox
[] Postman
[] Spotify

Then:

- **VS Code**: install the *WSL* extension; `code .` inside WSL then
  opens a remote window. Extensions/settings arrive via Settings
  Sync, same as on the mac.
- **Docker Desktop**: enable *Settings → Resources → WSL integration*
  so the `docker` CLI works inside Ubuntu.
- **GitKraken**: do **not** use the Windows/Store version if repos
  live in `~/work` on the Linux filesystem — GitKraken's own guidance
  is to keep the app on the same filesystem as the repos it opens, or
  risk degraded performance/broken features. 

  ```bash
  sudo apt install ./gitkraken-amd64.deb
  rm gitkraken-amd64.deb
  ```

  Launch with `gitkraken` (or `gitkraken ~/work/repo-name`) — WSLg
  (bundled with WSL2 on Windows 11, nothing extra to install) renders
  it as a normal-looking window on the Windows desktop, it's just
  actually running as a Linux binary.


## 8. Claude Code

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude --version
claude doctor
```

Run and log in from **inside WSL**, not PowerShell. First login opens
a browser; if it doesn't redirect back automatically (common on
WSL), it'll show a code — paste that into the WSL prompt instead.

Claude Code Desktop app also has a WSL-native mode: in the Code tab's
environment picker, choose the Ubuntu distribution directly rather
than opening the project over the `\\wsl$\` network path — same
performance reasoning as the GitKraken note above.

## 9. Quick check

New terminal, then:

```bash
echo $SHELL          # /usr/bin/zsh, custom prompt visible
git whoami           # work identity
node -v && npm -v && pnpm -v
bat --version && rg --version && gh --version
ssh -T git@github.com   # should NOT ask for a passphrase here
claude --version
```

Done.
