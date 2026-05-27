#!/usr/bin/env zsh
# macOS system preferences — replicates my setup on a fresh machine.
#
# Usage:
#   ./setup_macos.zsh            — apply all settings
#   ./setup_macos.zsh --dry-run  — preview what would change (no modifications)
#
# Each section shows the current value alongside the new value in dry-run mode.

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "\n🔍 DRY RUN — no changes will be made\n"
else
  echo "\n<<< Starting macOS setup >>>\n"
fi

# Helper: apply a defaults setting or print it in dry-run mode
# Usage: set_default <domain> <key> <type_flag> <value> <description>
set_default() {
  local domain="$1"
  local key="$2"
  local type_flag="$3"
  local value="$4"
  local description="$5"

  if $DRY_RUN; then
    local current
    current=$(defaults read "$domain" "$key" 2>/dev/null || echo "<not set>")
    printf "  %-55s  current=%-15s → %s\n" "$domain $key" "$current" "$value"
  else
    defaults write "$domain" "$key" "$type_flag" "$value"
    echo "  ✅  $description"
  fi
}

# ─── Dock ────────────────────────────────────────────────────────────────────
echo "=== Dock ==="

set_default com.apple.dock orientation          -string "left"  "Dock position: left"
set_default com.apple.dock tilesize             -int    33      "Dock icon size: 33px"
set_default com.apple.dock magnification        -bool   true    "Dock magnification: enabled"
set_default com.apple.dock largesize            -int    45      "Dock magnified icon size: 45px"
set_default com.apple.dock show-recents         -bool   false   "Dock: hide recent apps"
set_default com.apple.dock mru-spaces           -bool   false   "Dock: don't reorder Spaces by most recent use"
set_default com.apple.dock autohide             -bool   false   "Dock: always visible (not auto-hide)"

# Add folder stacks (Snips + Downloads) using dockutil if available
if ! $DRY_RUN; then
  if command -v dockutil &>/dev/null; then
    SNIPS="$HOME/Documents/Snips"
    DOWNLOADS="$HOME/Downloads"

    # Only add if not already present
    if ! dockutil --list | grep -q "Snips"; then
      dockutil --add "$SNIPS" --view fan --display folder --sort name --no-restart 2>/dev/null \
        && echo "  ✅  Dock: added Snips folder stack" \
        || echo "  ⚠️   Dock: could not add Snips (folder may not exist yet)"
    else
      echo "  ✅  Dock: Snips stack already present"
    fi

    if ! dockutil --list | grep -q "Downloads"; then
      dockutil --add "$DOWNLOADS" --view list --display stack --sort dateadded --no-restart 2>/dev/null \
        && echo "  ✅  Dock: added Downloads folder stack" \
        || echo "  ⚠️   Dock: could not add Downloads"
    else
      echo "  ✅  Dock: Downloads stack already present"
    fi
  else
    echo "  ⚠️   dockutil not installed — skipping folder stacks (run: brew install dockutil)"
  fi
else
  echo "  [dry-run] dockutil: would add Snips (fan/name) and Downloads (list/date) stacks"
fi

# ─── Keyboard ────────────────────────────────────────────────────────────────
echo "\n=== Keyboard ==="

set_default NSGlobalDomain KeyRepeat             -int   2    "Key repeat rate: fastest (2)"
set_default NSGlobalDomain InitialKeyRepeat      -int   25   "Initial key repeat delay: shortest (25)"
set_default NSGlobalDomain ApplePressAndHoldEnabled -bool false "Disable press-and-hold (enables key repeat)"
set_default NSGlobalDomain NSAutomaticCapitalizationEnabled     -bool false "Disable auto-capitalisation"
set_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false "Disable auto-correct"
set_default NSGlobalDomain NSAutomaticDashSubstitutionEnabled   -bool false "Disable smart dashes"
set_default NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled  -bool false "Disable smart quotes"
set_default NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false "Disable double-space period"

# ─── Trackpad ────────────────────────────────────────────────────────────────
echo "\n=== Trackpad ==="

set_default com.apple.AppleMultitouchTrackpad                  Clicking -bool true "Trackpad: tap to click"
set_default com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true "Trackpad: tap to click (Bluetooth)"
# Enable three-finger drag (system pref path)
set_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false "Trackpad: three-finger drag disabled (your setting)"

# ─── Screenshots ─────────────────────────────────────────────────────────────
echo "\n=== Screenshots ==="

if ! $DRY_RUN; then
  mkdir -p "$HOME/Documents/Snips"
  echo "  ✅  Created ~/Documents/Snips (if it didn't exist)"
fi

set_default com.apple.screencapture location      -string "$HOME/Documents/Snips" "Screenshot save location: ~/Documents/Snips"
set_default com.apple.screencapture showsClicks   -bool   true                    "Screenshots: show mouse clicks"
set_default com.apple.screencapture disable-shadow -bool  true                    "Screenshots: disable window shadow"

# ─── Finder ──────────────────────────────────────────────────────────────────
echo "\n=== Finder ==="

set_default NSGlobalDomain      AppleShowAllExtensions    -bool   true    "Finder: show all file extensions"
set_default com.apple.finder    ShowPathbar               -bool   true    "Finder: show path bar"
set_default com.apple.finder    ShowStatusBar             -bool   true    "Finder: show status bar"
set_default com.apple.finder    NewWindowTarget           -string "PfHm"  "Finder: new window opens Home folder"
set_default com.apple.finder    FXDefaultSearchScope      -string "SCcf"  "Finder: search current folder by default"
set_default com.apple.finder    FXEnableExtensionChangeWarning -bool false "Finder: no warning when changing extension"
set_default com.apple.finder    AppleShowAllFiles         -bool   true    "Finder: show hidden files"
set_default com.apple.desktopservices DSDontWriteNetworkStores -bool true "No .DS_Store on network volumes"
set_default com.apple.desktopservices DSDontWriteUSBStores     -bool true "No .DS_Store on USB drives"

# Finder sidebar: pin ~/Documents/Snips, ~/work, ~/projects
if ! $DRY_RUN; then
  for folder in "$HOME/Documents/Snips" "$HOME/work" "$HOME/projects"; do
    if [ -d "$folder" ]; then
      sfltool add-item com.apple.LSSharedFileList.FavoriteItems "file://$folder" 2>/dev/null \
        && echo "  ✅  Finder sidebar: added $folder" \
        || echo "  ⚠️   Finder sidebar: could not add $folder (may already be pinned)"
    else
      echo "  ⚠️   Finder sidebar: skipping $folder (directory doesn't exist)"
    fi
  done
else
  echo "  [dry-run] sfltool: would pin ~/Documents/Snips, ~/work, ~/projects to Finder sidebar"
fi

# ─── System / Quality of Life ────────────────────────────────────────────────
echo "\n=== System ==="

set_default NSGlobalDomain NSDocumentSaveNewDocumentsToCloud  -bool false "Save new documents to disk, not iCloud"
set_default NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true  "Expand save panel by default"
set_default NSGlobalDomain PMPrintingExpandedStateForPrint    -bool true  "Expand print panel by default"
set_default "com.apple.print.PrintingPrefs" "Quit When Finished" -bool true "Printer app: quit when finished"

# ─── Restart affected services ───────────────────────────────────────────────
if ! $DRY_RUN; then
  echo "\n=== Restarting services ==="
  killall Finder && echo "  ✅  Restarted Finder"
  killall Dock   && echo "  ✅  Restarted Dock"
  echo "\n✅  macOS setup complete."
  echo "⚠️   Some settings (keyboard repeat, trackpad) may require logging out to fully apply."
else
  echo "\n🔍 Dry run complete — no changes were made."
  echo "   Run without --dry-run to apply."
fi
