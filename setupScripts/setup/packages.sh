cat <<"EOF"
                  _
 _ __   __ _  ___| | ____ _  __ _  ___  ___
| '_ \ / _` |/ __| |/ / _` |/ _` |/ _ \/ __|
| |_) | (_| | (__|   < (_| | (_| |  __/\__ \
| .__/ \__,_|\___|_|\_\__,_|\__, |\___||___/
|_|                         |___/

EOF

#!/bin/bash
# Ensure yay is installed
if ! command -v yay &> /dev/null; then
    echo "yay is not installed. Installing yay..."
    sudo pacman -S yay --noconfirm
fi

# -------------------------------------------------------
# list of packages to install
# -------------------------------------------------------

packages=(
    "kitty"
    "pfetch"
    "neofetch"
    "btop"
    "baobab"
    "ripgrep"
    
    "discord"
    "telegram-desktop"
    "slack-desktop"
    
    "nnn"
    "gvfs-mtp"
    "w3m"
    "glow"
    "zathura"
    "zathura-pdf-poppler"
    "texlive"
    "xclip"
    
    "nautilus"
    "eog"
    "brave-bin"
    "google-chrome"
    
    "obs-studio"
    "zoom"
    "ffmpeg"
    "ffmpegthumbnailer"
    "zoom"
    "gimp"
    
    "notion-app-nativefier"
    "libreoffice-fresh"
    "fontpreview"
    "ttf-cascadia-code-nerd"
    "noto-fonts"
    "noto-fonts-cjk"
)

# -------------------------------------------------------
# Install the packages
# -------------------------------------------------------

for package in "${packages[@]}"; do
    if yay -Qi "$package" &> /dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package..."
        yay -S "$package" --noconfirm
    fi
done

echo "All packages installed!"
