#!/bin/bash

cat << "EOF"
       _   _
  __ _| |_| | __
 / _` | __| |/ /
| (_| | |_|   <
 \__, |\__|_|\_\
 |___/
EOF

packages=(
    "brightnessctl"
    "gum"
    "man-pages"
    "nm-connection-editor"

    "networkmanager"
    "network-manager-applet"
    "xarchiver"
    "zip"
    "fuse2"

    "qalculate-gtk"
    "imagemagick"
    "guvcview"
    "jq"
    "blueman"

    "gnome-tweaks"
    "gnome-shell-extensions"
    "gnome-shell-extension-dash-to-dock"
    "gnome-shell-extension-appindicator"
    "gnome-shell-extension-blur-my-shell"

    "colloid-gtk-theme-git"
    "colloid-icon-theme"
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
