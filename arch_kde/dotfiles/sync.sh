#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$1"
    local dest="$2"

    # Remove existing file, symlink, or directory to ensure clean link
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "Linked $src -> $dest"
}

echo "==> Linking home dotfiles (hidden files)"
if [ -d "$DOTFILES_DIR/home" ]; then
    # Use find to handle hidden files safely and avoid . and ..
    find "$DOTFILES_DIR/home" -maxdepth 1 -name ".*" -not -name "." -not -name ".." | while read -r file; do
        link "$file" "$HOME/$(basename "$file")"
    done
fi

echo "==> Linking ~/.config (General Apps)"
if [ -d "$DOTFILES_DIR/config" ]; then
    for item in "$DOTFILES_DIR/config"/*; do
        [ -e "$item" ] || continue # Handle empty directory case
        link "$item" "$HOME/.config/$(basename "$item")"
    done
fi

echo "==> Linking ~/.config (Hyprland Suite)"
if [ -d "$DOTFILES_DIR/hyprland" ]; then
    for item in "$DOTFILES_DIR/hyprland"/*; do
        [ -e "$item" ] || continue
        # Maps hyprland/hypr -> ~/.config/hypr, etc.
        link "$item" "$HOME/.config/$(basename "$item")"
    done
fi

echo "✅ All symlinks created"
