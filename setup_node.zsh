#!/usr/bin/env zsh
set -e

echo "\n<<< Starting Node.js setup >>>\n"

# Node versions are managed with nvm (installed via the Brewfile). nvm is loaded
# in zshrc, but this script runs as a non-interactive subprocess that only sources
# zshenv — so load nvm here too, otherwise `nvm` is not found on a fresh install.
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

if exists node; then
  echo "Node $(node -v) & NPM $(npm -v) already exist, skipping install"
else
  echo "Installing lts Node & NPM with nvm ..."
  nvm install --lts
fi

# Install global NPM packages
npm i -g trash-cli

echo "Global NPM packages installed:"
npm list --global --depth=0
