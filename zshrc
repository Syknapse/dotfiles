echo '.zshrc loaded'
echo 'Available aliases: lsf, eza, man, restart, brewbd, trail, mkcd, pn'
echo 'Aliases: lsf (ls -lAFh), eza (eza -lahF --git), man (batman), restart (source ~/.zshrc && source ~/.zshenv ), brewbd (brew bundle dump --force --describe), trail (<<<${(F)path}), mkcd (make a new directory and cd into it mkdc 'new_project'), pn (pnpm)'

# Variables
# -------------------------

# Disable MacOS gatekeeper when installing Brew casks
export HOMEBREW_CASK_OPTS="--no-quarantine"

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Make bat default instead of cat
export NULLCMD=bat

# ZSH Options
# -------------------------

# Aliases
# -------------------------

# More detailed version of ls
alias lsf='ls -lAFh'
# Much more detailed and colorful version of ls
alias eza='eza -lahF --git'
# A better version of the manual comand
alias man=batman
# Restsrt the shell implementing changes to zsh config files
alias restart='source ~/.zshrc && source ~/.zshenv '
# Brew bundle dump
alias brewbd='brew bundle dump --force --describe'
# A more readable way to print PATH variable
alias trail='<<<${(F)path}'
# A quicker way to type pnpm
alias pn='pnpm'

# Prompts
# -------------------------

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
PROMPT='
%F{33}%n@%m%f %F{201}%~%f %F{113}$(parse_git_branch)%f %F{222}%*%f %L %#
'

# Add locations to $path array variable
# -------------------------
# When you need to add to $PATH they go here in the path array

# Prevent duplicates in the path array
typeset -U path

path=(
  $path
  "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
)

# Functions
# -------------------------

# Create a new directory and cd to it
# USAGE: mkdc 'new_project'
function mkcd() {
  mkdir -p "$@" && cd "$_" 
}

function parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}

# ZSH Plugins
# -------------------------




