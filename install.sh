#!/bin/bash

# Ensure yay is installed
if ! command -v yay &> /dev/null; then
    echo "yay is not installed. Installing yay..."
    sudo pacman -S yay --noconfirm
fi

# List of packages to install
packages=(
    "visual-studio-code-bin"
    "nnn"
    "brave-bin"
    "cmatrix"
    "vlc"
    "catimg"
    "gnome-calculator"
    "discord"
    "telegram-desktop"
    "libreoffice-fresh"
    "libreoffice-still"
    "btop"
    "neovim"
    "obsidian"
    "zathura"
    "glow"
    "gimp"
)

# Install packages using yay
for package in "${packages[@]}"; do
    if yay -Qi "$package" &> /dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package..."
        yay -S --noconfirm "$package"
    fi
done

echo "All packages installed successfully."
