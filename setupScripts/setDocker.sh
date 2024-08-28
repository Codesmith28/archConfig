cat <<"EOF"
     _            _
  __| | ___   ___| | _____ _ __
 / _` |/ _ \ / __| |/ / _ \ '__|
| (_| | (_) | (__|   <  __/ |
 \__,_|\___/ \___|_|\_\___|_|


EOF

#!/bin/bash
echo "Preparing to setup Docker ..."

packages=(
    "docker"
    "docker-compose"
    "gnome-terminal"
    "docker-desktop"
)

for package in "${packages[@]}"; do
    if yay -Qi "$package" &> /dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package..."
        yay -S --noconfirm "$package"
    fi
done
echo "All required packages are installed!"


sudo systemctl enable --now docker.service
sudo systemctl start --now docker.service
sudo usermod -aG docker $USER
