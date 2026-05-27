#!/usr/bin/env zsh
# Generates an Ed25519 SSH key if one doesn't already exist.
# Idempotent — exits early if ~/.ssh/id_ed25519 is already present.
set -e

KEY="$HOME/.ssh/id_ed25519"
SSH_CONFIG="$HOME/.ssh/config"

echo "\n<<< Starting SSH setup >>>\n"

if [ -f "$KEY" ]; then
  echo "SSH key already exists at $KEY — skipping generation."
  echo "Public key:"
  cat "${KEY}.pub"
  exit 0
fi

# Read git email from ~/.gitconfig to use as the key comment
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
if [ -z "$GIT_EMAIL" ]; then
  echo "⚠️  Could not read git email from ~/.gitconfig"
  echo "    Using hostname as key comment instead."
  KEY_COMMENT="$(hostname)"
else
  KEY_COMMENT="$GIT_EMAIL"
fi

# Create ~/.ssh with correct permissions if it doesn't exist
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generate Ed25519 key (no passphrase by default — prompted interactively if desired)
echo "Generating Ed25519 SSH key for: $KEY_COMMENT"
ssh-keygen -t ed25519 -C "$KEY_COMMENT" -f "$KEY"

# Add to macOS Keychain via ssh-agent
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain "$KEY"

# Write ~/.ssh/config entry if not already present
if ! grep -q "UseKeychain yes" "$SSH_CONFIG" 2>/dev/null; then
  cat >> "$SSH_CONFIG" <<EOF

Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $KEY
EOF
  chmod 600 "$SSH_CONFIG"
  echo "  ✅  Added SSH config entry (~/.ssh/config)"
else
  echo "  ✅  SSH config already has UseKeychain entry"
fi

echo "\n✅  SSH key generated at $KEY"
echo ""
echo "══════════════════════════════════════════"
echo "  Copy this public key to GitHub:"
echo "  https://github.com/settings/ssh/new"
echo "══════════════════════════════════════════"
cat "${KEY}.pub"
echo "══════════════════════════════════════════"
