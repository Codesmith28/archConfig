#!/bin/bash

cat << "EOF"
  __             _                           __
 / _| ___  _ __ | |_ ___     ___ ___  _ __  / _|
| |_ / _ \| '_ \| __/ __|   / __/ _ \| '_ \| |_
|  _| (_) | | | | |_\__ \  | (_| (_) | | | |  _|
|_|  \___/|_| |_|\__|___/___\___\___/|_| |_|_|
                       |_____|
EOF

# Ensure the script runs with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (sudo)."
    exit 1
fi

# Verify directories exist before attempting removal
if [[ -d "/usr/share/fonts/noto" ]]; then
    rm -rf /usr/share/fonts/noto/*Mono*
    echo "Removed monospace fonts from /usr/share/fonts/noto"
else
    echo "Directory /usr/share/fonts/noto does not exist, skipping."
fi

if [[ -d "/usr/share/fonts/liberation" ]]; then
    rm -rf /usr/share/fonts/liberation/*Mono*
    echo "Removed monospace fonts from /usr/share/fonts/liberation"
else
    echo "Directory /usr/share/fonts/liberation does not exist, skipping."
fi

echo "Font cleanup complete."
