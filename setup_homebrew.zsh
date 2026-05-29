#!/usr/bin/env zsh
set -e

# Dry-run mode: set DOTFILES_DRY_RUN=1 or pass --dry-run to preview without changes.
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" || "$DOTFILES_DRY_RUN" == "1" ]]; then
  DRY_RUN=true
fi

# Resolve this script's own directory so sibling scripts work from any cwd.
SCRIPT_DIR="${0:A:h}"

# Tracks whether Homebrew was installed *in this run* — i.e. a brand-new machine.
# That's the one moment a Brewfile-drift pre-check is worth running (see below).
FRESH_BREW=false

echo "\n<<< Starting Homebrew setup >>>\n"

if exists brew; then
  echo "Brew already exists, skipping install"
elif $DRY_RUN; then
  echo "  [dry-run] Homebrew not found — would install it via the official install.sh"
else
  echo "Brew doesn't exist, installing ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Put brew in PATH for the rest of this script — the installer writes to ~/.zprofile
  # but that doesn't take effect in the current subprocess.
  eval "$(/opt/homebrew/bin/brew shellenv)"
  FRESH_BREW=true
fi


# brew bundle can't take --no-quarantine as a flag, so it must come from the
# HOMEBREW_CASK_OPTS env var. zshrc exports it for interactive shells, but this
# script runs as a non-interactive subprocess that doesn't source zshrc — so
# export it here too, otherwise every cask installed on a fresh machine gets
# quarantined and trips Gatekeeper on first launch.
# https://github.com/Homebrew/homebrew-bundle/issues/474
export HOMEBREW_CASK_OPTS="--no-quarantine"

# Brewfile-drift pre-check — runs ONLY on a brand-new machine (FRESH_BREW), never
# on re-runs and never in dry-run. This is the one moment drift matters: it flags
# packages renamed/removed upstream right before we install them. Advisory only
# (`|| echo`) — brew bundle below still attempts everything and reports failures.
if $FRESH_BREW && [ -x "$SCRIPT_DIR/test/brewfile-drift.sh" ]; then
  echo "Checking the Brewfile against upstream before the first install ..."
  "$SCRIPT_DIR/test/brewfile-drift.sh" || \
    echo "⚠️  Brewfile drift detected (see above) — install continues; update the Brewfile when convenient."
fi

# A single flaky/removed package must not abort the whole install — macOS
# settings and SSH setup still need to run. brew bundle is in an `elif`
# condition so `set -e` won't trip on a non-zero exit; we warn and continue.
if $DRY_RUN; then
  echo "  [dry-run] would run: brew bundle --verbose  (HOMEBREW_CASK_OPTS=$HOMEBREW_CASK_OPTS)"
elif brew bundle --verbose; then
  echo "All Brewfile packages installed."
else
  echo "\n⚠️  Some Homebrew packages failed to install (see above)."
  echo "    Continuing with the rest of the setup — re-run 'brew bundle' (or './install') to retry them."
fi
