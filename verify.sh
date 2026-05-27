#!/usr/bin/env bash
# Post-install smoke test — checks the current state without modifying anything.
# Safe to run at any time. Exit code 0 = all checks passed.

PASS=0
FAIL=0

ok()   { echo "  ✅  $1"; ((PASS++)); }
fail() { echo "  ❌  $1"; ((FAIL++)); }
warn() { echo "  ⚠️   $1"; }
header() { echo ""; echo "=== $1 ==="; }

# ─── Symlinks ────────────────────────────────────────────────────────────────
header "Symlinks"

check_link() {
  local link="$1"
  local expected_target="$2"
  if [ -L "$link" ]; then
    local actual; actual=$(readlink "$link")
    if [ "$actual" = "$expected_target" ]; then
      ok "$link → $actual"
    else
      fail "$link points to '$actual', expected '$expected_target'"
    fi
  else
    fail "$link is missing or not a symlink"
  fi
}

DOTS="$HOME/.dotfiles"
check_link "$HOME/.zshrc"   "$DOTS/zshrc"
check_link "$HOME/.zshenv"  "$DOTS/zshenv"
check_link "$HOME/.zprofile" "$DOTS/zprofile"
check_link "$HOME/.gitconfig" "$DOTS/gitconfig"
check_link "$HOME/.gitignore" "$DOTS/gitignore"

if [ -L "$HOME/.secrets" ]; then
  ok "$HOME/.secrets → $(readlink "$HOME/.secrets")"
else
  warn "$HOME/.secrets is not symlinked — copy secrets.example → secrets and re-run ./install"
fi

if [ -L "$HOME/.config/bat" ]; then
  ok "$HOME/.config/bat → $(readlink "$HOME/.config/bat")"
else
  fail "$HOME/.config/bat symlink missing"
fi

# ─── Directories ─────────────────────────────────────────────────────────────
header "Directories"

for dir in "$HOME/projects" "$HOME/work" "$HOME/Documents/Snips"; do
  if [ -d "$dir" ]; then
    ok "$dir exists"
  else
    fail "$dir is missing"
  fi
done

# ─── Homebrew packages ───────────────────────────────────────────────────────
header "Homebrew"

if command -v brew &>/dev/null; then
  ok "brew installed ($(brew --version | head -1))"
  if brew bundle check --file="$DOTS/Brewfile" &>/dev/null; then
    ok "All Brewfile packages installed"
  else
    # Collect specific missing packages
    missing=$(brew bundle check --file="$DOTS/Brewfile" --verbose 2>&1 | grep "^→" | sed 's/^→ //')
    fail "Some Brewfile dependencies unmet — run: brew bundle"
    while IFS= read -r line; do
      warn "  $line"
    done <<< "$missing"
  fi
else
  fail "brew not found"
fi

# ─── Shell ───────────────────────────────────────────────────────────────────
header "Shell"

EXPECTED_SHELL="/opt/homebrew/bin/zsh"
if [ "$SHELL" = "$EXPECTED_SHELL" ]; then
  ok "Default shell is Homebrew ZSH ($SHELL)"
else
  fail "Default shell is '$SHELL', expected '$EXPECTED_SHELL'"
fi

if grep -q "$EXPECTED_SHELL" /etc/shells; then
  ok "$EXPECTED_SHELL listed in /etc/shells"
else
  fail "$EXPECTED_SHELL not in /etc/shells"
fi

# ─── SSH ─────────────────────────────────────────────────────────────────────
header "SSH"

if [ -f "$HOME/.ssh/id_ed25519" ]; then
  ok "SSH key exists (~/.ssh/id_ed25519)"
else
  warn "No SSH key at ~/.ssh/id_ed25519 — run: ./setup_ssh.zsh"
fi

if grep -q "UseKeychain yes" "$HOME/.ssh/config" 2>/dev/null; then
  ok "$HOME/.ssh/config has UseKeychain entry"
else
  warn "$HOME/.ssh/config missing UseKeychain — run: ./setup_ssh.zsh"
fi

# ─── macOS defaults ──────────────────────────────────────────────────────────
header "macOS settings"

check_default() {
  local domain="$1"
  local key="$2"
  local expected="$3"
  local label="$4"
  local actual
  actual=$(defaults read "$domain" "$key" 2>/dev/null || echo "<not set>")
  # Normalise ~ to $HOME for path comparisons
  actual="${actual/#\~/$HOME}"
  expected="${expected/#\~/$HOME}"
  if [ "$actual" = "$expected" ]; then
    ok "$label ($actual)"
  else
    fail "$label — expected '$expected', got '$actual'"
  fi
}

check_default "com.apple.dock"       "orientation"          "left"  "Dock orientation: left"
check_default "com.apple.dock"       "tilesize"             "33"    "Dock tile size: 33"
check_default "com.apple.dock"       "show-recents"         "0"     "Dock: no recent apps"
check_default "NSGlobalDomain"       "KeyRepeat"            "2"     "Key repeat: fastest"
check_default "NSGlobalDomain"       "InitialKeyRepeat"     "25"    "Initial key repeat: shortest"
check_default "NSGlobalDomain"       "AppleShowAllExtensions" "1"   "Finder: show all extensions"
check_default "com.apple.screencapture" "location"  "$HOME/Documents/Snips" "Screenshots → ~/Documents/Snips"

# ─── Result ──────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────"
if [ "$FAIL" -gt 0 ]; then
  echo "Result: $FAIL check(s) FAILED, $PASS passed"
  exit 1
else
  echo "Result: all $PASS checks passed ✅"
fi
