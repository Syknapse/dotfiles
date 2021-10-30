#|/usr/bin/env zsh

echo "\n<<< Starting Homebrew setup >>>\n"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install httpie
brew install bat

# Casks
brew tap homebrew/cask

brew install google-chrome
brew install visual-studio-code
