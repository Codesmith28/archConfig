#!/bin/bash

cat << "EOF"
 _ __ ___ _ __ ___   __ _ _ __
| '__/ _ \ '_ ` _ \ / _` | '_ \
| | |  __/ | | | | | (_| | |_) |
|_|  \___|_| |_| |_|\__,_| .__/
                         |_|
EOF

# Install keyd
if ! command -v keyd &>/dev/null; then
    echo "Installing keyd..."
    sudo pacman -S keyd --noconfirm
else
    echo "Keyd is already installed."
fi

# Enable and start keyd service
if ! systemctl is-active --quiet keyd; then
    echo "Enabling and starting keyd service..."
    sudo systemctl enable --now keyd
else
    echo "Keyd service is already running."
fi

# Get the absolute path of the script
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIGURATION_FILE="$SCRIPT_DIR/configurations/default.conf"

# Copy configuration if it exists
if [[ -f "$CONFIGURATION_FILE" ]]; then
    echo "Configuration file found. Copying to /etc/keyd/default.conf"
    sudo cp "$CONFIGURATION_FILE" /etc/keyd/default.conf
else
    echo "Configuration file not found. Using existing configuration."
fi

# Restart keyd to apply changes
echo "Restarting keyd..."
sudo systemctl restart keyd

echo "Keyd setup complete."
