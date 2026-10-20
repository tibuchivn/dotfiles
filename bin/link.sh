#!/usr/bin/env bash
# link.sh — tạo symlink từ $HOME vào repo dotfiles cho các config TĨNH.
# Idempotent: chạy lại nhiều lần vẫn an toàn.
#
# Config do app tự ghi (opencode, claude, hermes) KHÔNG symlink —
# dùng ./sync.sh để chụp lại và bin/restore.sh để khôi phục.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME}"

STATIC_PATHS=(
  .zshrc
  .zprofile
  .zshenv
  .gitconfig
  .gitignore_global
  .tmux.conf
  .tmux.conf.local
  .config/mise.toml
  .config/starship.toml
  .config/alacritty/alacritty.toml
  .config/alacritty/presentation.toml
  .config/kitty/kitty.conf
  .config/nvim
  .config/nvim_bk
  .config/jev
  .hammerspoon
)

linked=0; skipped=0
for rel in "${STATIC_PATHS[@]}"; do
  src="$HOME_DIR/$rel"
  dst="$REPO/$rel"
  if [ ! -e "$dst" ]; then
    echo "MISSING in repo: $rel (bỏ qua)"
    continue
  fi
  if [ -L "$src" ]; then
    skipped=$((skipped+1)); continue
  fi
  if [ -e "$src" ]; then
    backup="$src.pre-dotfiles-$(date +%Y%m%d-%H%M%S)"
    echo "BACKUP $rel -> $backup"
    mv "$src" "$backup"
  fi
  mkdir -p "$(dirname "$src")"
  ln -s "$dst" "$src"
  echo "LINKED $rel"
  linked=$((linked+1))
done

echo "---"
echo "linked=$linked already_linked=$skipped"
echo "Nhắc: cp $REPO/.zsh_secrets.example ~/.zsh_secrets && chmod 600 ~/.zsh_secrets"
