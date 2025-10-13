#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Detecting system and selecting package manager..."

# Determine package manager
if command -v zypper &> /dev/null; then
  PM="zypper"
  INSTALL="sudo zypper install -y"
elif command -v apt &> /dev/null; then
  PM="apt"
  sudo apt update
  INSTALL="sudo apt install -y"
elif command -v dnf &> /dev/null; then
  PM="dnf"
  INSTALL="sudo dnf install -y"
elif command -v pacman &> /dev/null; then
  PM="pacman"
  sudo pacman -Sy
  INSTALL="sudo pacman -S --noconfirm"
else
  echo "❌ Unsupported package manager. Install packages manually."
  exit 1
fi

echo "📦 Using package manager: $PM"

# Install essential packages
echo "🔧 Installing zsh, git, curl, wget, python3, nodejs, npm..."
$INSTALL zsh git curl wget python3 nodejs npm

# Install GitHub CLI
if ! command -v gh &> /dev/null; then
  echo "🐙 Installing GitHub CLI (gh)..."
  if [[ "$PM" == "zypper" ]]; then
    sudo zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo
    sudo rpm --import https://cli.github.com/packages/githubcli-archive-keyring.gpg
    $INSTALL gh
  elif [[ "$PM" == "apt" ]]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    $INSTALL gh
  else
    $INSTALL gh
  fi
fi

# Install Tailscale
if ! command -v tailscale &> /dev/null; then
  echo "🌐 Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# Install Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "💡 Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "✅ Oh My Zsh already installed."
fi

# Set zsh as default shell
if [[ "$SHELL" != *zsh ]]; then
  echo "🌀 Changing default shell to zsh..."
  chsh -s "$(which zsh)"
fi

# Install Codex CLI globally
if ! command -v codex &> /dev/null; then
  echo "🤖 Installing Codex CLI (OpenAI)..."
  sudo npm install -g codex-cli
fi

echo
echo "✅ All set. You can now run:"
echo "   → 'exec zsh' to enter zsh"
echo "   → 'gh auth login' to authenticate GitHub CLI"
echo "   → 'tailscale up' to connect"
echo "   → 'codex' to use Codex CLI"
