#!/bin/bash

cat << "EOF"
     _                                _
  __| | _____   __   _ __   __ _  ___| | ____ _  __ _  ___  ___
 / _` |/ _ \ \ / /  | '_ \ / _` |/ __| |/ / _` |/ _` |/ _ \/ __|
| (_| |  __/\ V /   | |_) | (_| | (__|   < (_| | (_| |  __/\__ \
 \__,_|\___| \_/____| .__/ \__,_|\___|_|\_\__,_|\__, |\___||___/
              |_____|_|                         |___/
EOF


packages=(
    "vim"
    "visual-studio-code-bin"
    "neovim"
    "distrobox"
    "mongodb-compass"
    "clang"
    "go"
    "fzf"
    "zsh"
    "bat"
    "nvm"
    "pnpm"
    "yarn"
    "typescript"
    "ts-node"
    "bun"
    "python-pipx"
)

for package in "${packages[@]}"; do
    if yay -Qi "$package" &> /dev/null; then
        echo "$package is already installed. Skipping..."
    else
        if [[ " ${packagesPacman[*]} " =~ " ${package} " ]]; then
            echo "Installing $package from pacman..."
            sudo pacman -S "$package" --noconfirm
        else
            echo "Installing $package from yay..."
            yay -S "$package" --noconfirm
        fi
    fi
done

echo "All packages installed!"
