#!/bin/bash

cat << "EOF"
                  _                 _
  __ _ _ __ _   _| |__     ___  ___| |_ _   _ _ __
 / _` | '__| | | | '_ \   / __|/ _ \ __| | | | '_ \
| (_| | |  | |_| | |_) |  \__ \  __/ |_| |_| | |_) |
 \__, |_|   \__,_|_.__/___|___/\___|\__|\__,_| .__/
 |___/               |_____|                 |_|
EOF

# Ensure the script runs with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (sudo)."
    exit 1
fi

# Get the script's directory
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Install os-prober
echo "Installing os-prober..."
pacman -S --noconfirm os-prober

# Copy grub config using absolute path
echo "Copying grub configuration..."
cp "$SCRIPT_DIR/grub" /etc/default/grub

# Generate new GRUB configuration
echo "Updating GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "Grub setup complete."
