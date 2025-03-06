#!/bin/bash

cat << "EOF"
     _
  __| | _____   __  ___ _ ____   __
 / _` |/ _ \ \ / / / _ \ '_ \ \ / /
| (_| |  __/\ V / |  __/ | | \ V /
 \__,_|\___| \_/___\___|_| |_|\_/
              |_____|
EOF

packages=(
    "go"
    "rust"
    "rust-analyzer"
    "rustup"
    "nvm"
    "pnpm"
    "yarn"
    "typescript"
    "ts-node"
    "bun"
    "python-pipx"
)

# -------------------------------------------------------
# Install packages using yay
# -------------------------------------------------------

for package in "${packages[@]}"; do
    if yay -Qi "$package" &> /dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package..."
        sudo yay -S --noconfirm "$package"
    fi
done
echo "All required packages are installed!"

# Ensure pipx path
pipx ensurepath

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
