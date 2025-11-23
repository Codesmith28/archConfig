#!/bin/bash

cat <<"EOF"
 _ _       _           _       _
| (_)_ __ | | __    __| | ___ | |_ ___
| | | '_ \| |/ /   / _` |/ _ \| __/ __|
| | | | | |   <   | (_| | (_) | |_\__ \
|_|_|_| |_|_|\_\___\__,_|\___/ \__|___/
              |_____|
EOF

# Resolve absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_SRC="$SCRIPT_DIR/../../dotfiles"
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
CACHE_DIR="$HOME/.cache"

# Ensure required directories exist
mkdir -p "$DOTFILES_DIR" "$CONFIG_DIR" "$CACHE_DIR"

# Copy dotfiles from source to dotfiles directory (only missing files)
echo "Syncing dotfiles from $DOTFILES_SRC to $DOTFILES_DIR..."
rsync -av --ignore-existing "$DOTFILES_SRC"/ "$DOTFILES_DIR"

echo "Processing symlinks for dotfiles..."

# Iterate through dotfiles directory
for item in "$DOTFILES_DIR"/*; do
    name=$(basename "$item")
    target="$CONFIG_DIR/$name"
    target_cache="$CACHE_DIR/$name"

    case "$name" in
        ".settings")
            echo "Handling .settings..."
            ln -sf "$DOTFILES_DIR/.settings" "$HOME/.config/.settings"
            ;;
        ".zshrc" | ".bashrc" | ".profile")
            echo "Handling $name..."
            ln -sf "$DOTFILES_DIR/$name" "$HOME/$name"
            ;;
        "wal" | "wallpaper_cache")
            echo "Handling cache symlink for $name..."
            [[ -e "$target_cache" || -L "$target_cache" ]] && rm -rf "$target_cache"
            ln -s -r "$item" "$target_cache"
            ;;
        *)
            if [[ -d "$item" ]]; then
                if [[ -d "$target" ]]; then
                    echo "Merging directory $name into $target"
                    rsync -av "$item"/ "$target"
                else
                    echo "Creating symlink for $name in config directory..."
                    ln -s -r "$item" "$target"
                fi
            elif [[ -f "$item" ]]; then
                [[ -e "$target" || -L "$target" ]] && rm -f "$target"
                echo "Creating symlink for $name in config directory..."
                ln -s -r "$item" "$target"
            fi
            ;;
    esac
done

echo "Dotfiles setup completed!"
