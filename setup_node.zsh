#!/usr/bin/env zsh
set -e

# Dry-run mode: set DOTFILES_DRY_RUN=1 or pass --dry-run to preview without changes.
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" || "$DOTFILES_DRY_RUN" == "1" ]]; then
  DRY_RUN=true
fi

echo "\n<<< Starting Node.js setup >>>\n"

# Node versions are managed with nvm (installed via the Brewfile). nvm is loaded
# in zshrc, but this script runs as a non-interactive subprocess that only sources
# zshenv — so load nvm here too, otherwise `nvm` is not found on a fresh install.
export NVM_DIR="$HOME/.nvm"
$DRY_RUN || mkdir -p "$NVM_DIR"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# In dry-run we still load nvm above, so a broken loader surfaces here instead of
# on install day. Fail loudly if it didn't resolve, then preview the install steps.
if $DRY_RUN; then
  if command -v nvm >/dev/null 2>&1; then
    echo "  [dry-run] nvm loaded OK (v$(nvm --version)); would run: nvm install --lts (if node missing)"
  else
    echo "  [dry-run] ERROR: nvm did not load — a real install would fail at 'nvm install'"
    exit 1
  fi
  echo "  [dry-run] would run: npm i -g trash-cli"
  exit 0
fi

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
