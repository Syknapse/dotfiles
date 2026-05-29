#!/usr/bin/env bash
# Sandbox install harness — the closest thing to a fresh-machine test without a
# fresh machine. It runs the REAL ./install into a throwaway $HOME with every
# privileged/interactive/heavy step neutralised, twice, and asserts both the
# fresh-install result and idempotency on the second run.
#
# It makes NO changes to your real machine: $HOME is a temp dir, the environment
# is wiped (env -i) so nothing leaks in, and the setup_*.zsh scripts run in
# DOTFILES_DRY_RUN mode (no brew install, chsh, sudo, ssh-keygen or defaults).
#
# Phase 1 — full ./install into a sandbox HOME, run twice (orchestration + links
#           + secrets + idempotency, plus the env-propagation checks that the
#           nvm and HOMEBREW_CASK_OPTS fixes depend on).
# Phase 2 — the append-once logic (ssh `Host *`, /etc/shells) exercised with REAL
#           writes into a sandbox, using shims for the privileged commands, run
#           twice to prove no duplicate blocks.
#
# Exit 0 = everything passed. Safe to run anytime; CI runs it on every push.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# A minimal PATH with the real tools install needs (git, zsh, python3, brew),
# but WITHOUT the caller's env — so a missing in-script `export` is caught.
CLEANPATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

PASS=0; FAIL=0
ok()   { echo "  ✅  $1"; PASS=$((PASS + 1)); }
no()   { echo "  ❌  $1"; FAIL=$((FAIL + 1)); }
hdr()  { echo ""; echo "=== $1 ==="; }

# assert_link <link> <expected_target> <label>
assert_link() {
  local link="$1" want="$2" label="$3" got
  if [ -L "$link" ] && got="$(readlink "$link")" && [ "$got" = "$want" ]; then
    ok "$label"
  else
    no "$label (got '${got:-missing}', want '$want')"
  fi
}
# assert_contains <file> <substring> <label>
assert_contains() {
  if grep -qF "$2" "$1" 2>/dev/null; then ok "$3"; else no "$3"; fi
}
# assert_count <file> <ERE> <n> <label>
assert_count() {
  local n; n="$(grep -cE "$2" "$1" 2>/dev/null || true)"
  if [ "$n" = "$3" ]; then ok "$4 (count=$n)"; else no "$4 (count=$n, want $3)"; fi
}

CLEANUP=()
cleanup() { for d in "${CLEANUP[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done; }
trap cleanup EXIT

# ── Phase 1: full ./install into a sandbox HOME, twice ────────────────────────
hdr "Phase 1: ./install into a sandbox HOME (clean env, dry-run)"

SANDBOX="$(mktemp -d)"; CLEANUP+=("$SANDBOX")
LOG1="$SANDBOX/.run1.log"; LOG2="$SANDBOX/.run2.log"

env -i HOME="$SANDBOX" PATH="$CLEANPATH" DOTFILES_DRY_RUN=1 TERM=dumb \
  "$REPO/install" >"$LOG1" 2>&1
rc1=$?
# Capture after run 1 (when secrets is guaranteed to exist) so the idempotency
# check below works on a fresh CI checkout where secrets didn't exist yet.
secrets_md5_run1="$(md5 -q "$REPO/secrets" 2>/dev/null || echo none)"

if [ "$rc1" -eq 0 ]; then ok "first install exited 0"; else no "first install exited $rc1 (see below)"; fi

for pair in \
  ".zshrc:zshrc" ".zshenv:zshenv" ".zprofile:zprofile" \
  ".gitconfig:gitconfig" ".gitignore:gitignore" ".secrets:secrets" \
  ".config/bat:config/bat"; do
  link="${pair%%:*}"; src="${pair##*:}"
  assert_link "$SANDBOX/$link" "$REPO/$src" "linked ~/$link"
done

if [ -d "$SANDBOX/projects" ]; then ok "created ~/projects"; else no "missing ~/projects"; fi
if [ -d "$SANDBOX/work" ];     then ok "created ~/work";     else no "missing ~/work";     fi

# secrets file is created (from template) and locked down
if [ -f "$REPO/secrets" ]; then
  mode="$(stat -f '%Lp' "$REPO/secrets")"
  if [ "$mode" = "600" ]; then ok "secrets is mode 600"; else no "secrets is mode $mode (want 600)"; fi
else
  no "secrets file was not created"
fi

# The fixes we depend on, observed in the REAL execution path under a clean env:
assert_contains "$LOG1" "HOMEBREW_CASK_OPTS=--no-quarantine" \
  "brew bundle would run WITH --no-quarantine (cask fix)"
assert_contains "$LOG1" "nvm loaded OK" \
  "nvm loads in the setup subprocess (nvm fix)"
assert_contains "$LOG1" "All tasks executed successfully" \
  "dotbot reported overall success"
if grep -qiE "command not found|no such file|unbound variable" "$LOG1"; then
  no "install log contains an error signature"
else
  ok "install log has no error signatures"
fi

# ── Phase 1 second run: idempotency ───────────────────────────────────────────
hdr "Phase 1: second run (idempotency)"

env -i HOME="$SANDBOX" PATH="$CLEANPATH" DOTFILES_DRY_RUN=1 TERM=dumb \
  "$REPO/install" >"$LOG2" 2>&1
rc2=$?

if [ "$rc2" -eq 0 ]; then ok "second install exited 0"; else no "second install exited $rc2"; fi
assert_link "$SANDBOX/.zshrc"  "$REPO/zshrc"  "links still correct after re-run"
assert_contains "$LOG2" "All tasks executed successfully" "dotbot success on re-run"

secrets_md5_run2="$(md5 -q "$REPO/secrets" 2>/dev/null || echo none)"
if [ "$secrets_md5_run1" = "$secrets_md5_run2" ]; then
  ok "secrets file unchanged across runs (real keys safe)"
else
  no "secrets file CHANGED across runs"
fi

# ── Phase 2: append-once logic with real writes + shims ───────────────────────
hdr "Phase 2: append-once idempotency (ssh Host*, /etc/shells)"

SHIMS="$(mktemp -d)"; CLEANUP+=("$SHIMS")
cat >"$SHIMS/ssh-keygen" <<'SH'
#!/usr/bin/env bash
f=""; while [ $# -gt 0 ]; do case "$1" in -f) f="$2"; shift 2;; *) shift;; esac; done
[ -n "$f" ] && { : > "$f"; echo "ssh-ed25519 AAAATEST test@sandbox" > "$f.pub"; }
exit 0
SH
printf '#!/usr/bin/env bash\nexit 0\n'        >"$SHIMS/ssh-add"
printf '#!/usr/bin/env bash\nexit 0\n'        >"$SHIMS/ssh-agent"
printf '#!/usr/bin/env bash\nexit 0\n'        >"$SHIMS/chsh"
printf '#!/usr/bin/env bash\nexec "$@"\n'     >"$SHIMS/sudo"   # run the cmd, drop privilege
chmod +x "$SHIMS"/*
SHIMPATH="$SHIMS:$CLEANPATH"

# --- ssh: fresh run writes exactly one Host * block ---
H="$(mktemp -d)"; CLEANUP+=("$H")
env -i HOME="$H" PATH="$SHIMPATH" zsh -c "cd '$REPO' && ./setup_ssh.zsh" >/dev/null 2>&1
assert_count "$H/.ssh/config" '^[[:space:]]*Host[[:space:]]+\*[[:space:]]*$' 1 \
  "ssh: fresh run writes one Host * block"

# --- ssh: re-running the config logic (key removed) does not duplicate ---
rm -f "$H/.ssh/id_ed25519"
env -i HOME="$H" PATH="$SHIMPATH" zsh -c "cd '$REPO' && ./setup_ssh.zsh" >/dev/null 2>&1
assert_count "$H/.ssh/config" '^[[:space:]]*Host[[:space:]]+\*[[:space:]]*$' 1 \
  "ssh: re-run detects existing Host * and does not duplicate"

# --- ssh: a pre-existing (foreign) Host * block is left untouched ---
H2="$(mktemp -d)"; CLEANUP+=("$H2")
mkdir -p "$H2/.ssh"; printf 'Host *\n  ForwardAgent yes\n' >"$H2/.ssh/config"
env -i HOME="$H2" PATH="$SHIMPATH" zsh -c "cd '$REPO' && ./setup_ssh.zsh" >/dev/null 2>&1
assert_count "$H2/.ssh/config" '^[[:space:]]*Host[[:space:]]+\*[[:space:]]*$' 1 \
  "ssh: existing foreign Host * is not duplicated"
if grep -qF "IdentityFile" "$H2/.ssh/config"; then
  no "ssh: clobbered a user's existing Host * block"
else
  ok "ssh: left the user's existing Host * block untouched"
fi

# --- /etc/shells: append-once via SHELLS_FILE seam ---
SH_FILE="$(mktemp)"; CLEANUP+=("$SH_FILE")
: > "$SH_FILE"
for _ in 1 2; do
  env -i HOME="$(mktemp -d)" PATH="$SHIMPATH" SHELLS_FILE="$SH_FILE" SHELL=/bin/bash \
    zsh -c "cd '$REPO' && ./setup_zsh.zsh" >/dev/null 2>&1
done
assert_count "$SH_FILE" '^/opt/homebrew/bin/zsh$' 1 \
  "shells: zsh path added exactly once across two runs"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────"
if [ "$FAIL" -gt 0 ]; then
  echo "Result: $FAIL check(s) FAILED, $PASS passed"
  echo ""
  echo "First-run log tail (for debugging):"
  tail -25 "$LOG1" 2>/dev/null | sed 's/^/    /'
  exit 1
fi
echo "Result: all $PASS sandbox checks passed ✅"
