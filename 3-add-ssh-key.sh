#!/usr/bin/env bash
set -euo pipefail

KEY_NAME="torberglund@universal"
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY_PATH="$SSH_DIR/id_ed25519"
PUBLIC_KEY_PATH="$SSH_DIR/id_ed25519.pub"

echo "🔐 Fetching private key '$KEY_NAME' from 1Password..."

# Create .ssh dir if needed
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Fetch and write private key
op item get "$KEY_NAME" --fields private_key --reveal > "$PRIVATE_KEY_PATH"
chmod 600 "$PRIVATE_KEY_PATH"

echo "🛠 Generating public key from private key..."
ssh-keygen -y -f "$PRIVATE_KEY_PATH" > "$PUBLIC_KEY_PATH"
chmod 644 "$PUBLIC_KEY_PATH"

echo "✅ SSH key installed:"
echo "   🔑 $PRIVATE_KEY_PATH"
echo "   🗝  $PUBLIC_KEY_PATH"

# Optionally load into ssh-agent
if command -v ssh-add >/dev/null 2>&1; then
  echo "🚀 Adding key to ssh-agent..."
  eval "$(ssh-agent -s)"
  ssh-add "$PRIVATE_KEY_PATH"
fi
