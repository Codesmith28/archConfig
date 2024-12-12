#!/bin/bash

cat << "EOF"
                 _ _   _                    _ _
 _ __ ___  _   _| | |_(_)_ __ ___   ___  __| (_) __ _
| '_ ` _ \| | | | | __| | '_ ` _ \ / _ \/ _` | |/ _` |
| | | | | | |_| | | |_| | | | | | |  __/ (_| | | (_| |
|_| |_| |_|\__,_|_|\__|_|_| |_| |_|\___|\__,_|_|\__,_|

EOF

packages=(
    "obs-studio"
    "mpv"
    "spotify-adblock"
    "zoom"
    "ffmpeg"
    "ffmpegthumbnailer"
    "xwaylandvideobridge"
    "gimp"
    "libreoffice-fresh"
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
