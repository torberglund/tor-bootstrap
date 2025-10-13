#!/usr/bin/env bash
shopt -s expand_aliases
set -e
# sudo apt update && sudo apt install -y zsh git curl && git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k && chsh -s $(which zsh)
# 1. Clone bare repo if it doesn't already exist
if [ ! -d "$HOME/.dotfiles" ]; then
  git clone --bare https://github.com/torberglund/dotfiles.git ~/.dotfiles
fi

# 2. Temporary alias for the bare repo
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# 3. Ensure required directories exist
mkdir -p ~/.zsh

# 4. Fetch latest commits (create remote refs if missing)
dot fetch origin main || true

# 5. Guarantee a valid local branch 'main' pointing to origin/main
if ! dot rev-parse --verify main >/dev/null 2>&1; then
  dot symbolic-ref HEAD refs/heads/main || true
  if dot show-ref --verify refs/remotes/origin/main >/dev/null 2>&1; then
    dot branch -f main refs/remotes/origin/main
  else
    dot branch -f main FETCH_HEAD
  fi
fi

# 6. Force overwrite local files to match remote
dot reset --hard refs/remotes/origin/main || dot reset --hard FETCH_HEAD

# 7. Hide untracked clutter
dot config status.showUntrackedFiles no

echo "✅ Dotfiles fully synced (always overwrites local configs). Restart terminal or run: exec zsh"
