#!/bin/bash

cat <<"EOF"
     _            _
  __| | ___   ___| | _____ _ __
 / _` |/ _ \ / __| |/ / _ \ '__|
| (_| | (_) | (__|   <  __/ |
 \__,_|\___/ \___|_|\_\___|_|

EOF

echo "Preparing to setup Docker ..."

packages=(
    "docker"
    "docker-compose"
    "gnome-terminal"
)

for package in "${packages[@]}"; do
    if pacman -Qq "$package" &> /dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package..."
        yay -S --noconfirm "$package"
    fi
done
echo "All required packages are installed!"

sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"

echo "Docker setup complete!"
echo "You must log out and log back in (or restart) for the group changes to take effect."
