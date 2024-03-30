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

# List of packages to install
packages=(
    "pfetch"
    "bibata-cursor-theme"
    "trizen"
    "pacseek"
    "visual-studio-code-bin"
    "nnn"
    "brave-bin"
    "cmatrix-git"
    "vlc"
    "obs-studio"
    "ueberzugpp"
    "discord"
    "telegram-desktop"
    "libreoffice-still"
    "btop"
    "neovim"
    "obsidian"
    "zathura"
    "texlive"
    "gimp"
    "clang"
    "neofetch"
    "baobab"
    "zathura-pdf-poppler"
    "zsh"
    "gvfs-mtp"
    "github-cli"
    "slack-desktop"
    "bat"
    "zoom"
    "fontpreview"
    "w3m"
    "glow"
    "ffmpeg"
    "ffmpegthumbnailer"
    "mpv"
    "bsdtar"
    "ttf-cascadia-code-nerd"
    "noto-fonts"
    "noto-fonts-cjk"
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
