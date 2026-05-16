#!/bin/bash

cat << "EOF"
 _                      _                 _
| |__  _   _ _ __  _ __| | __ _ _ __   __| |
| '_ \| | | | '_ \| '__| |/ _` | '_ \ / _` |
| | | | |_| | |_) | |  | | (_| | | | | (_| |
|_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
       |___/|_|
EOF

packages=(
    "rofi-wayland"
    "hyprland"
    "hyprpaper"
    "hyprlock"
    "hypridle"
    "hyprshade"
    "hyprshot"
    "hyprswitch"

    "waybar"
    "grim"
    "slurp"
    "swappy"
    "cliphist"
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
