# Variables
# Syntax highlighting for man pages using bat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ZSH Options

# Aliases
alias lsf='ls -lAFh'

# Prompts
PROMPT='
%n@%m %1~ %L %#
'

RPROMPT='%*'

# Add locations to $PATH variable

# Functions
function mkcd() {
  mkdir -p "$@" && cd "$_" 
}

# ZSH Plugins
