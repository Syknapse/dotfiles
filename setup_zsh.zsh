#!/usr/bin/env zsh
set -e

# Dry-run mode: set DOTFILES_DRY_RUN=1 or pass --dry-run to preview without changes.
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" || "$DOTFILES_DRY_RUN" == "1" ]]; then
  DRY_RUN=true
fi

# Override the shells file in tests so we never touch the real /etc/shells.
SHELLS_FILE="${SHELLS_FILE:-/etc/shells}"

echo "\n<<< Starting ZSH setup >>>\n"

# We do not need to install zsh here because it is in the brewfile and will be installed

# Change default shell to the one installed by brew (instead of the one in /bin/zsh)

if grep -Fxq '/opt/homebrew/bin/zsh' "$SHELLS_FILE" 2>/dev/null; then
  echo "Already added Homebrew ZSH to acceptable shells: /opt/homebrew/bin/zsh exists in $SHELLS_FILE"
elif $DRY_RUN; then
  echo "  [dry-run] would add /opt/homebrew/bin/zsh to $SHELLS_FILE (requires sudo)"
else
  echo "Enter superuser (sudo) password to edit $SHELLS_FILE"
  echo '/opt/homebrew/bin/zsh' | sudo tee -a "$SHELLS_FILE" >/dev/null
fi

if [ "$SHELL" = '/opt/homebrew/bin/zsh' ]; then
  echo "Already using Homebrew ZSH as default user shell ($SHELL)"
elif $DRY_RUN; then
  echo "  [dry-run] would run: chsh -s /opt/homebrew/bin/zsh"
else
  echo "Enter user password to change login shell"
  chsh -s '/opt/homebrew/bin/zsh'
fi

