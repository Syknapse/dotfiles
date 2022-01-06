echo '.zshrc loaded'
# Variables
# -------------------------

# Disable MacOS gatekeeper when installing Brew casks
export HOMEBREW_CASK_OPTS="--no-quarantine"
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# ZSH Options
# -------------------------

# Aliases
# -------------------------

# More detailed version of ls
alias lsf='ls -lAFh'
# Much more detailed and colorful version of ls
alias exa='exa -laFh --git'
# A better version of the manual comand
alias man=batman
# Restsrt the shell implementing changes to zsh config files
alias restart='source ~/.zshrc && source ~/.zshenv '

# Prompts
# -------------------------

PROMPT='
%n@%m %1~ %L %#
'

RPROMPT='%*'

# Add locations to $PATH variable
# -------------------------

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# Functions
# -------------------------

function mkcd() {
  mkdir -p "$@" && cd "$_" 
}

# ZSH Plugins
# -------------------------

