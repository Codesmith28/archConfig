#!/bin/bash

cat << "EOF"
     _
  __| | _____   __  ___ _ ____   __
 / _` |/ _ \ \ / / / _ \ '_ \ \ / /
| (_| |  __/\ V / |  __/ | | \ V /
 \__,_|\___| \_/___\___|_| |_|\_/
              |_____|
EOF

# Ensure pipx path
pipx ensurepath

# Set go environment
if ! command -v go &> /dev/null
then
    echo "Go is not installed. Installing Go..."
    sudo pacman -S --noconfirm go
    echo "Go installed and configured."
else
    echo "Go is already installed."
fi

# Set rust environment
if ! command -v rustc &> /dev/null
then
    echo "Rust is not installed. Installing Rust..."
    sudo pacman -S --noconfirm rustup
    rustup default stable
    echo "Rust installed and configured."
else
    echo "Rust is already installed."
fi
