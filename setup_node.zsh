#!/usr/bin/env zsh

echo "\n<<< Starting Node.js setup >>>\n"

# Node versions are managed with nvm which is in the Brewfile

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
