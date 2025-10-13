#!/usr/bin/env bash
set -e

# Automatically detect system architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH=amd64 ;;
  i386|i686) ARCH=386 ;;
  armv7l) ARCH=arm ;;
  aarch64) ARCH=arm64 ;;
  *) echo "❌ Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

echo "📦 Installing 1Password CLI for architecture: $ARCH"

# Download and install op CLI
wget "https://cache.agilebits.com/dist/1P/op2/pkg/v2.32.0/op_linux_${ARCH}_v2.32.0.zip" -O op.zip
unzip -d op op.zip
sudo mv op/op /usr/local/bin/
rm -r op.zip op

# Set permissions
sudo groupadd -f onepassword-cli
sudo chgrp onepassword-cli /usr/local/bin/op
sudo chmod g+s /usr/local/bin/op

echo "✅ 1Password CLI installed at /usr/local/bin/op"
echo "👉 Log in with:"
echo "   op account add --address my.1password.com --email tor.berglund@gmail.com"
