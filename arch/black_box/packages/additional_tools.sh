#!/bin/bash

cat << "EOF"
           _     _ _ _   _                   _
  __ _  __| | __| (_) |_(_) ___  _ __   __ _| |
 / _` |/ _` |/ _` | | __| |/ _ \| '_ \ / _` | |
| (_| | (_| | (_| | | |_| | (_) | | | | (_| | |
 \__,_|\__,_|\__,_|_|\__|_|\___/|_| |_|\__,_|_|

EOF

packages=(
    "eza"
    "python-pip"
    "python-psutil"
    "python-rich"
    "python-click"
    "python-pywal"
    "python-gobject"
    "pavucontrol"
    "tumbler"

    "wlogout"
    "nwg-look"
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
