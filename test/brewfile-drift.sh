#!/usr/bin/env bash
# Brewfile drift check — catches the "the cask vanished/was renamed the day I
# installed" class of failure (e.g. docker -> docker-desktop) BEFORE install day.
#
# For every formula/cask in the Brewfile it asks Homebrew for the *canonical*
# token and compares it to what's written. A token can still "resolve" after a
# rename (Homebrew redirects old names), so resolution alone isn't enough — we
# compare names to spot renames, plus flag anything deprecated/disabled/missing.
#
# Best run on a schedule (upstream changes on its own clock, not yours). Needs
# network + brew. Exit 0 = no drift.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$REPO/Brewfile"
export HOMEBREW_NO_AUTO_UPDATE=1   # don't mutate tap state just to read info

PASS=0; WARN=0; FAIL=0
ok()   { echo "  ✅  $1"; PASS=$((PASS + 1)); }
warn() { echo "  ⚠️   $1"; WARN=$((WARN + 1)); }
no()   { echo "  ❌  $1"; FAIL=$((FAIL + 1)); }

if ! command -v brew >/dev/null 2>&1; then
  echo "brew not found — cannot check Brewfile drift." >&2
  exit 1
fi

# Ensure declared taps are present so tap-qualified tokens resolve (idempotent).
echo "=== Taps ==="
while IFS= read -r tap; do
  [ -z "$tap" ] && continue
  if brew tap | grep -qxF "$tap"; then
    ok "tap $tap (present)"
  elif brew tap "$tap" >/dev/null 2>&1; then
    ok "tap $tap (added)"
  else
    no "tap $tap could not be added"
  fi
done < <(grep -E '^tap "' "$BREWFILE" | sed -E 's/^tap "([^"]+)".*/\1/')

# check_token <formula|cask> <token>
check_token() {
  local kind="$1" tok="$2" out canonical canon_base req_base
  if ! out="$(brew info "--$kind" "$tok" 2>/dev/null)"; then
    no "$kind $tok — does NOT resolve (removed or renamed away)"
    return
  fi
  # First line looks like: "==> <canonical>: ..." (formula) or "==> <canonical> (..." (cask)
  canonical="$(printf '%s\n' "$out" | sed -n '1s/^==> \([^ :(]*\).*/\1/p')"
  canon_base="${canonical##*/}"
  req_base="${tok##*/}"
  if [ -n "$canonical" ] && [ "$canon_base" != "$req_base" ]; then
    no "$kind $tok — RENAMED to '$canonical' (update the Brewfile)"
  elif printf '%s\n' "$out" | grep -qiE '(is deprecated|is disabled|^Disabled|deprecated!)'; then
    warn "$kind $tok — deprecated/disabled upstream"
  else
    ok "$kind $tok"
  fi
}

echo ""
echo "=== Formulae ==="
while IFS= read -r f; do
  [ -n "$f" ] && check_token formula "$f"
done < <(grep -E '^brew "' "$BREWFILE" | sed -E 's/^brew "([^"]+)".*/\1/')

echo ""
echo "=== Casks ==="
while IFS= read -r c; do
  [ -n "$c" ] && check_token cask "$c"
done < <(grep -E '^cask "' "$BREWFILE" | sed -E 's/^cask "([^"]+)".*/\1/')

# Mac App Store entries can't be validated without network/region/sign-in — list them.
mas_lines="$(grep -E '^mas ' "$BREWFILE" || true)"
if [ -n "$mas_lines" ]; then
  echo ""
  echo "=== Mac App Store (not auto-validated) ==="
  printf '%s\n' "$mas_lines" | while IFS= read -r m; do echo "  ℹ️   $m"; done
fi

echo ""
echo "─────────────────────────────────"
if [ "$FAIL" -gt 0 ]; then
  echo "Result: $FAIL drift issue(s), $WARN warning(s), $PASS ok ❌"
  exit 1
fi
echo "Result: no drift — $PASS ok, $WARN warning(s) ✅"
