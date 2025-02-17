#!/bin/bash

DOTFILES_DIR=../../dotfiles/
CONFIG_DIR=~/.config/

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: $DOTFILES_DIR does not exist."
    exit 1
fi

if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: $CONFIG_DIR does not exist."
    exit 1
fi

echo "Symlinking $DOTFILES_DIR to $CONFIG_DIR"

for item in "$DOTFILES_DIR"/*; do
    name=$(basename "$item")
    target="$CONFIG_DIR/$name"

    if [[ -e "$target" ]]; then
        echo "Skipping $name: Target already exists."
    else
        if [[ -d "$item" ]]; then
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
