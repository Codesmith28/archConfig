#!/bin/bash

cat <<"EOF"
 _ _       _           _       _
| (_)_ __ | | __    __| | ___ | |_ ___
| | | '_ \| |/ /   / _` |/ _ \| __/ __|
| | | | | |   <   | (_| | (_) | |_\__ \
|_|_|_| |_|_|\_\___\__,_|\___/ \__|___/
              |_____|
EOF

DOTFILES_SRC=../../dotfiles/
DOTFILES_DIR=~/dotfiles/
CONFIG_DIR=~/.config/
CACHE_DIR=~/.cache/

# Ensure required directories exist
mkdir -p "$DOTFILES_DIR" "$CONFIG_DIR" "$CACHE_DIR"

# Copy dotfiles from source to dotfiles directory
echo "Copying dotfiles from $DOTFILES_SRC to $DOTFILES_DIR"
rsync -av --ignore-existing "$DOTFILES_SRC"/ "$DOTFILES_DIR"

echo "Symlinking $DOTFILES_DIR to $CONFIG_DIR"

for item in "$DOTFILES_DIR"/*; do
    name=$(basename "$item")
    target="$CONFIG_DIR/$name"
    target_cache="$CACHE_DIR/$name"

    # Handle directories (merge instead of replace)
    if [[ -d "$item" ]]; then
        if [[ -d "$target" ]]; then
            echo "Merging directory $item into $target"
            rsync -av "$item"/ "$target"
        else
            echo "Creating symlink for $name in config directory..."
            ln -s -r "$item" "$target"
        fi
    # Handle files (replace existing files)
    elif [[ -f "$item" ]]; then
        if [[ -e "$target" || -L "$target" ]]; then
            echo "Replacing existing file $target"
            rm -f "$target"
        fi
        echo "Creating symlink for $name in config directory..."
        ln -s -r "$item" "$target"
    fi

    # Handle cache-specific items
    if [[ "$name" == "wal" || "$name" == "wallpaper_cache" ]]; then
        if [[ -e "$target_cache" || -L "$target_cache" ]]; then
            echo "Removing existing $target_cache"
            rm -rf "$target_cache"
        fi
        echo "Creating symlink for $name in cache directory..."
        ln -s -r "$item" "$target_cache"
    fi
done

echo "All files and directories processed successfully!"
