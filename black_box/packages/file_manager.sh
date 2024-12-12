#!/bin/bash
cat << "EOF"
  __ _ _
 / _(_) | ___     _ __ ___   __ _ _ __   __ _  __ _  ___ _ __
| |_| | |/ _ \   | '_ ` _ \ / _` | '_ \ / _` |/ _` |/ _ \ '__|
|  _| | |  __/   | | | | | | (_| | | | | (_| | (_| |  __/ |
|_| |_|_|\___|___|_| |_| |_|\__,_|_| |_|\__,_|\__, |\___|_|
            |_____|                           |___/
EOF

packages=(
    "nautilus"
    "eog"
    "unzip"
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
