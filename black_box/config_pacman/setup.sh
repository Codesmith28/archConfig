#!/bin/bash

cat << "EOF"
 _ __   __ _  ___ _ __ ___   __ _ _ __      ___ ___  _ __  / _|
| '_ \ / _` |/ __| '_ ` _ \ / _` | '_ \    / __/ _ \| '_ \| |_
| |_) | (_| | (__| | | | | | (_| | | | |  | (_| (_) | | | |  _|
| .__/ \__,_|\___|_| |_| |_|\__,_|_| |_|___\___\___/|_| |_|_|
|_|                                   |_____|

EOF

# Ensure the script runs with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (sudo)."
    exit 1
fi

# Get the script's directory
SCRIPT_DIR=$(dirname "$(realpath "$0")")

echo "Setting up pacman..."

# Copy pacman.conf using absolute path
cp "$SCRIPT_DIR/pacman.conf" /etc/

echo "Pacman setup complete."
