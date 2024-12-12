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

packagesPacman=(
    # General
    "kitty"
    "fastfetch"
    "btop"
    "ripgrep"
    "baobab"
    
    # Communication
    "discord"
    "telegram-desktop"
    
    # Utilities
    "gvfs"
    "w3m"
    "glow"
    "zathura"
    "zathura-pdf-poppler"
    "texlive"
    "xclip"
    "less"
    
    # File Managers
    "nautilus"
    "eog"
    "unzip"
    
    # Multimedia
    "obs-studio"
    "mpv"
    "spotify-adblock"
    "zoom"
    "ffmpeg"
    "ffmpegthumbnailer"
    "xwaylandvideobridge"
    "gimp"
    "libreoffice-fresh"
    
    # System Tools
    "pacman-contrib"
    "bluez"
    "bluez-utils"
    "wget"
    "firefox"
    "dunst"
    "starship"
    
    # Additional Tools
    "eza"
    "python-pip"
    "python-psutil"
    "python-rich"
    "python-click"
    "python-pywal"
    "python-gobject"
    "pavucontrol"
    "tumbler"
    
    # GNOME and GTK
    "colloid-icon-theme-git"
    "polkit-gnome"
    "brightnessctl"
    "gum"
    "man-pages"
    "nm-connection-editor"
    "xdg-user-dirs"
    "xdg-desktop-portal-gtk"
    "networkmanager"
    "network-manager-applet"
    "xarchiver"
    "zip"
    "fuse2"
    "gtk4"
    "libadwaita"
    "xdg-desktop-portal"
    "qalculate-gtk"
    "imagemagick"
    "guvcview"
    "jq"
    "rofi-wayland"
    "blueman"
    
    # Fonts
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
    
    # Hyprland Components
    "hyprland"
    "hyprpaper"
    "hyprlock"
    "hypridle"
    "hyprshade"
    "hyprshot"
    "xdg-desktop-portal-hyprland"
    
    # Wayland Utilities
    "waybar"
    "grim"
    "slurp"
    "swappy"
    "cliphist"
)

packagesYay=(
    # Additional Tools
    "wlogout"
    "nwg-look"
)

# Merge both arrays
allPackages=("${packagesPacman[@]}" "${packagesYay[@]}")

# -------------------------------------------------------
# Install the packages
# -------------------------------------------------------

for package in "${allPackages[@]}"; do
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
