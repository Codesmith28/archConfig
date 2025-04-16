#!/bin/bash

cat << "EOF"
               _                    _              _
 ___ _   _ ___| |_ ___ _ __ ___    | |_ ___   ___ | |___
/ __| | | / __| __/ _ \ '_ ` _ \   | __/ _ \ / _ \| / __|
\__ \ |_| \__ \ ||  __/ | | | | |  | || (_) | (_) | \__ \
|___/\__, |___/\__\___|_| |_| |_|___\__\___/ \___/|_|___/
     |___/                     |_____|
EOF

packages=(
    "pacman-contrib"
    "bluez"
    "bluez-utils"
    "wget"
    "dunst"
    "starship"
    "dhcpcd"
    "iwd"
    "networkmanager"
    "xdg-desktop-portal-hyprland"
    "gtk"

    "cmake"
    "cpio"
    "meson"
    "pkg-config"
    "swww"
    "wireplumber"
    "pipewire-pulse"
    "rsync"
    "7zip"
    "net-tools"
    "expect"

    "cliphist"
    "wl-clipboard"
    "wl-clip-persist"

    "wlroots"
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
