#!/usr/bin/env zsh
set -e

echo "\n<<< Starting Homebrew setup >>>\n"

if exists brew; then
  echo "Brew already exists, skipping install"
else
  echo "Brew doesn't exist, installing ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Put brew in PATH for the rest of this script — the installer writes to ~/.zprofile
  # but that doesn't take effect in the current subprocess.
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi


# TODO: Keep an eye out for a different `--no-quarantine` solution.
# Currently, you can't do `brew bundle --no-quarantine` as an option.
# It's currently exported in zshrc:
# export HOMEBREW_CASK_OPTS="--no-quarantine"
# https://github.com/Homebrew/homebrew-bundle/issues/474

brew bundle --verbose
