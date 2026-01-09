#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1"
  local dest="$2"

  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "Linked $src -> $dest"
}

echo "==> Linking home dotfiles"
if [ -d "$DOTFILES_DIR/home" ]; then
  for file in "$DOTFILES_DIR/home"/.*; do
    [ "$(basename "$file")" = "." ] && continue
    [ "$(basename "$file")" = ".." ] && continue
    link "$file" "$HOME/$(basename "$file")"
  done
fi

echo "==> Linking ~/.config"
if [ -d "$DOTFILES_DIR/config" ]; then
  for item in "$DOTFILES_DIR/config"/*; do
    link "$item" "$HOME/.config/$(basename "$item")"
  done
fi

echo "✅ All symlinks created"

