#!/bin/bash

DOTFILES_SRC=../../dotfiles/
DOTFILES_DIR=~/dotfiles/
CONFIG_DIR=~/.config/
CACHE_DIR=~/.cache/

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "$DOTFILES_DIR does not exist."
    mkdir "$DOTFILES_DIR"
fi

if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: $CONFIG_DIR does not exist."
    mkdir "$CONFIG_DIR"
fi

# copy from dotfiles src to dotfiles dir
echo "Copying dotfiles from $DOTFILES_SRC to $DOTFILES_DIR"
cp -r "$DOTFILES_SRC"/* "$DOTFILES_DIR"

echo "Symlinking $DOTFILES_DIR to $CONFIG_DIR"

for item in "$DOTFILES_DIR"/*; do
    name=$(basename "$item")
    target="$CONFIG_DIR/$name"
    target_cache="$CACHE_DIR/$name"

    if [[ -e "$target" || -e "$target_cache" ]]; then
        echo "Skipping $name: Target already exists."
    else
        # move wal and wallpaper_cache to cache dir
        if [[ "$name" == "wal" || "$name" == "wallpaper_cache" ]]; then
            echo "Creating symlink for $name in cache directory..."
            ln -s -r "$item" "$target_cache"
        # symlink everything else
        elif [[ -d "$item" ]]; then
            echo "Creating recursive symlink for directory $name..."
            ln -s -r "$item" "$target"
        elif [[ -f "$item" ]]; then
            echo "Creating symlink for file $name..."
            ln -s "$item" "$target"
        else
            echo "Skipping $name: Not a regular file or directory."
            continue
        fi
    fi
done

echo "All files and directories symlinked successfully!"
