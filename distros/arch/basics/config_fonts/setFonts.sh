#!/bin/bash

echo "Get Ubuntu Nerd Fonts and JetBrainsMono Nerd Fonts from Nerd fonts"
ehco "put them under /usr/share/fonts/custom/"
echo ""

sudo cp ./local.conf /etc/fonts/local.conf
echo "font confif under /etc/fonts/local.conf is now set!"
echo ""

# Verify directories exist before attempting removal

echo "Removing default monospace fonts to avoid conflicts..."

# Remove Noto Mono fonts
if [[ -d "/usr/share/fonts/noto" ]]; then
    sudo rm -rf /usr/share/fonts/noto/*Mono*
    echo "Removed monospace fonts from /usr/share/fonts/noto"
else
    echo "Directory /usr/share/fonts/noto does not exist, skipping."
fi

# Remove Liberation Mono fonts
if [[ -d "/usr/share/fonts/liberation" ]]; then
    sudo rm -rf /usr/share/fonts/liberation/*Mono*
    echo "Removed monospace fonts from /usr/share/fonts/liberation"
else
    echo "Directory /usr/share/fonts/liberation does not exist, skipping."
fi

echo "Font cleanup complete."

echo "updating font cache"
sudo fc-cache -fv
echo ""
