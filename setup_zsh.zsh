#!/usr/bin/env zsh

echo "\n<<< Starting ZSH setup >>>\n"

# We do not need to install zsh here because it is in the brewfile and will be installed

# Change default shell to the one installed by brew (instead of the one in /bin/zsh)

if grep -Fxq '/opt/homebrew/bin/zsh' '/etc/shells'; then
  echo 'Already added Homebrew ZSH to acceptable shells: /opt/homebrew/bin/zsh exists in /etc/shells'
else
  echo "Enter superuser (sudo) password to edit /etc/shells"
  echo '/opt/homebrew/bin/zsh' | sudo tee -a '/etc/shells' >/dev/null
fi

if [ "$SHELL" = '/opt/homebrew/bin/zsh' ]; then
  echo 'Already using Hombrew ZSH as default user shell: $SHELL is /opt/homebrew/bin/zsh'
else
  echo "Enter user password to change login shell"
  chsh -s '/opt/homebrew/bin/zsh'
fi

