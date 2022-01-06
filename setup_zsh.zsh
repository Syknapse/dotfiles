#!/usr/bin/env zsh

echo "\n<<< Starting ZSH setup >>>\n"

# We do not need to install zsh here because it is in the brewfile and will be installed

# Change default shell to the one installed by brew (instead of the one in /bin/zsh)
echo "Enter superuser (sudo) password to edit /etc/shells"
echo '/opt/homebrew/bin/zsh' | sudo tee -a '/etc/shells' >/dev/null

echo "Enter user password to change login shell"
chsh -s '/opt/homebrew/bin/zsh'
