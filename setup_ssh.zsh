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

# Write a catch-all (`Host *`) entry — but only if one doesn't already exist,
# so we never append a second, conflicting `Host *` block to a config the user
# (or another tool) has already set up.
if grep -qE '^[[:space:]]*Host[[:space:]]+\*[[:space:]]*$' "$SSH_CONFIG" 2>/dev/null; then
  echo "  ⚠️   ~/.ssh/config already has a 'Host *' block — leaving it untouched."
  echo "      Make sure it includes these lines:"
  echo "        AddKeysToAgent yes"
  echo "        UseKeychain yes"
  echo "        IdentityFile $KEY"
else
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  cat >> "$SSH_CONFIG" <<EOF

Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $KEY
EOF
  echo "  ✅  Added SSH config entry (~/.ssh/config)"
fi

echo "\n✅  SSH key generated at $KEY"
echo ""
echo "══════════════════════════════════════════"
echo "  Copy this public key to GitHub:"
echo "  https://github.com/settings/ssh/new"
echo "══════════════════════════════════════════"
cat "${KEY}.pub"
echo "══════════════════════════════════════════"
