#!/usr/bin/env bash
# Syntax-check all shell scripts without executing them.
# Safe to run at any time — makes no changes.
set -e
shopt -s nullglob   # unmatched globs expand to nothing instead of a literal

PASS=0
FAIL=0

echo ""
echo "=== Syntax check (zsh -n) ==="
for f in *.zsh; do
  if zsh -n "$f" 2>&1; then
    echo "  ✅  $f"
    ((PASS++))
  else
    echo "  ❌  $f"
    ((FAIL++))
  fi
done

echo ""
echo "=== shellcheck ==="
if command -v shellcheck &>/dev/null; then
  # Note: shellcheck doesn't support zsh natively; --shell=bash is close enough.
  # SC2028 (echo \n) is a known false positive for zsh.
  # SC1091 (can't follow sourced file) fires on the nvm loader, whose path only
  # exists at runtime after Homebrew installs nvm — nothing to follow statically.
  for f in *.zsh *.sh test/*.sh .githooks/*; do
    if shellcheck --shell=bash --exclude=SC2028,SC1091 "$f" 2>&1; then
      echo "  ✅  $f"
    else
      echo "  ⚠️   $f (see above)"
    fi
  done
else
  echo "  shellcheck not installed — run: brew install shellcheck"
fi

echo ""
echo "=== YAML syntax (install.conf.yaml) ==="
if command -v python3 &>/dev/null && python3 -c "import yaml" 2>/dev/null; then
  if python3 -c "import yaml; yaml.safe_load(open('install.conf.yaml'))" 2>&1; then
    echo "  ✅  install.conf.yaml"
  else
    echo "  ❌  install.conf.yaml"
    ((FAIL++))
  fi
elif command -v yq &>/dev/null; then
  if yq '.' install.conf.yaml >/dev/null 2>&1; then
    echo "  ✅  install.conf.yaml"
  else
    echo "  ❌  install.conf.yaml"
    ((FAIL++))
  fi
elif command -v ruby &>/dev/null; then
  # ruby ships with macOS, so the validator is always available here and in CI.
  if ruby -ryaml -e "YAML.load_file('install.conf.yaml')" 2>&1; then
    echo "  ✅  install.conf.yaml"
  else
    echo "  ❌  install.conf.yaml"
    ((FAIL++))
  fi
else
  # No validator at all — fail loudly rather than silently skipping.
  echo "  ❌  No YAML validator found (need python-yaml, yq, or ruby)"
  ((FAIL++))
fi

echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "Result: $FAIL failure(s), $PASS passed ❌"
  exit 1
else
  echo "Result: all $PASS scripts passed ✅"
fi
