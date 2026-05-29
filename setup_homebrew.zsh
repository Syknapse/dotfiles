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


# brew bundle can't take --no-quarantine as a flag, so it must come from the
# HOMEBREW_CASK_OPTS env var. zshrc exports it for interactive shells, but this
# script runs as a non-interactive subprocess that doesn't source zshrc — so
# export it here too, otherwise every cask installed on a fresh machine gets
# quarantined and trips Gatekeeper on first launch.
# https://github.com/Homebrew/homebrew-bundle/issues/474
export HOMEBREW_CASK_OPTS="--no-quarantine"

brew bundle --verbose
