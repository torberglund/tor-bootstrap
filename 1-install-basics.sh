#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Detecting system and selecting package manager..."

# --- Initialization ---
declare -A STATUS
function mark_status() {
  local key="$1"
  local result="$2"
  STATUS["$key"]="$result"
}

# --- Detect package manager ---
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

# --- Install essential packages ---
ESSENTIALS=(zsh git curl wget python3 nodejs npm ca-certificates)
echo "🔧 Installing essentials: ${ESSENTIALS[*]}"
if $INSTALL "${ESSENTIALS[@]}"; then
  mark_status "Essentials" "✅"
else
  mark_status "Essentials" "❌"
fi



# --- GitHub CLI ---
if ! command -v gh &> /dev/null; then
  echo "🐙 Installing GitHub CLI (gh)..."
  if [[ "$PM" == "zypper" ]]; then
    sudo zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo || true
    sudo rpm --import https://cli.github.com/packages/githubcli-archive-keyring.gpg || true
    $INSTALL gh && mark_status "GitHub CLI" "✅" || mark_status "GitHub CLI" "❌"
  elif [[ "$PM" == "apt" ]]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    if $INSTALL gh; then mark_status "GitHub CLI" "✅"; else mark_status "GitHub CLI" "❌"; fi
  elif [[ "$PM" == "pacman" ]]; then
    $INSTALL github-cli && mark_status "GitHub CLI" "✅" || mark_status "GitHub CLI" "❌"
  else
    $INSTALL gh || $INSTALL github-cli && mark_status "GitHub CLI" "✅" || mark_status "GitHub CLI" "❌"
  fi
else
  echo "✅ GitHub CLI already installed."
  mark_status "GitHub CLI" "✅"
fi

# --- Tailscale ---
if ! command -v tailscale &> /dev/null; then
  echo "🌐 Installing Tailscale..."
  if curl -fsSL https://tailscale.com/install.sh | sh; then
    mark_status "Tailscale" "✅"
  else
    mark_status "Tailscale" "❌"
  fi
else
  mark_status "Tailscale" "✅"
fi

# --- Oh My Zsh ---
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "💡 Installing Oh My Zsh..."
  if RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    mark_status "Oh My Zsh" "✅"
  else
    mark_status "Oh My Zsh" "❌"
  fi
else
  mark_status "Oh My Zsh" "✅"
fi

# --- Powerlevel10k theme ---
ZSH_PATH=$(which zsh)
if ! grep -q "$ZSH_PATH" /etc/shells; then
  echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
fi
if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k 2>/dev/null; then
  mark_status "Powerlevel10k" "✅"
else
  mark_status "Powerlevel10k" "⚠️ (already exists or failed)"
fi

# --- Set zsh default ---
if [[ "$SHELL" != *zsh ]]; then
  echo "🌀 Changing default shell to zsh..."
  if chsh -s "$ZSH_PATH"; then
    mark_status "Default Shell (zsh)" "✅"
  else
    mark_status "Default Shell (zsh)" "❌"
  fi
else
  mark_status "Default Shell (zsh)" "✅"
fi

# --- Codex CLI ---
if ! command -v codex &> /dev/null; then
  echo "🤖 Installing Codex CLI..."
  if sudo npm install -g codex-cli; then
    mark_status "Codex CLI" "✅"
  else
    mark_status "Codex CLI" "❌"
  fi
else
  mark_status "Codex CLI" "✅"
fi

# --- Fonts ---
echo "🎨 Installing MesloLGS Nerd Fonts..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
cd "$FONT_DIR"
if wget -q \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf; then
  fc-cache -fv >/dev/null 2>&1
  mark_status "Meslo Nerd Fonts" "✅"
else
  mark_status "Meslo Nerd Fonts" "❌"
fi

# --- Summary ---
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 INSTALLATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for key in "${!STATUS[@]}"; do
  printf "%-25s %s\n" "$key" "${STATUS[$key]}"
done
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "✅ All done! You can now run:"
echo "   → 'exec zsh' to start Zsh"
echo "   → 'gh auth login' to authenticate GitHub"
echo "   → 'tailscale up' to connect"
echo "   → 'codex' to use Codex CLI"
echo "   → Set terminal font to 'MesloLGS NF' for Powerlevel10k"

