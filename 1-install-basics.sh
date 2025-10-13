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
  INSTALL="sudo pacman -Sy --noconfirm"
else
  echo "❌ Unsupported package manager. Install packages manually."
  exit 1
fi

echo "📦 Using package manager: $PM"

# Install essential packages
echo "🔧 Installing zsh, git, curl, wget, python3, nodejs, npm, ca-certificates..."
$INSTALL zsh git curl wget python3 nodejs npm ca-certificates

# Install GitHub CLI
if ! command -v gh &> /dev/null; then
  echo "🐙 Installing GitHub CLI (gh)..."
  if [[ "$PM" == "zypper" ]]; then
    sudo zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo
    sudo rpm --import https://cli.github.com/packages/githubcli-archive-keyring.gpg
    $INSTALL gh
  elif [[ "$PM" == "apt" ]]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    $INSTALL gh
  elif [[ "$PM" == "pacman" ]]; then
    $INSTALL github-cli
  else
    $INSTALL gh || $INSTALL github-cli
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

# Ensure zsh is listed in /etc/shells (for chsh to work)
ZSH_PATH=$(which zsh)
if ! grep -q "$ZSH_PATH" /etc/shells; then
  echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
fi

# Set zsh as default shell
if [[ "$SHELL" != *zsh ]]; then
  echo "🌀 Changing default shell to zsh..."
  chsh -s "$ZSH_PATH"
fi

# Install Codex CLI
if ! command -v codex &> /dev/null; then
  echo "🤖 Installing Codex CLI (OpenAI)..."
  sudo npm install -g codex-cli
fi

# Install Meslo Nerd Fonts
echo "🎨 Installing MesloLGS Nerd Font for Powerlevel10k..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
cd "$FONT_DIR"

wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

fc-cache -fv

echo
echo "✅ All set. You can now run:"
echo "   → 'exec zsh' to enter zsh"
echo "   → 'gh auth login' to authenticate GitHub CLI"
echo "   → 'tailscale up' to connect"
echo "   → 'codex' to use Codex CLI"
echo "   → Set terminal font to 'MesloLGS NF' for Powerlevel10k to render properly"
