#!/bin/bash
cat << "EOF"
  __             _                         _
 / _| ___  _ __ | |_      _ __   __ _  ___| | ____ _  __ _  ___  ___
| |_ / _ \| '_ \| __|    | '_ \ / _` |/ __| |/ / _` |/ _` |/ _ \/ __|
|  _| (_) | | | | |_     | |_) | (_| | (__|   < (_| | (_| |  __/\__ \
|_|  \___/|_| |_|\__|____| .__/ \__,_|\___|_|\_\__,_|\__, |\___||___/
                   |_____|_|                         |___/
EOF

packages=(
    "noto-fonts"
    "noto-fonts-cjk"
    "otf-font-awesome"
    "ttf-fira-sans"
    "ttf-firacode-nerd"
    "ttf-recursive-nerd"
    "ttf-cascadia-code-nerd"
    "ttf-jetbrains-mono-nerd"
    "figlet"
    "fontpreview"
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
