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
    "rustup"
    "rust-analyzer"
    "nvm"
    "pnpm"
    "yarn"
    "typescript"
    "ts-node"
    "bun"
    "python-pipx"
    "openssl"
    "zlib"
    "xz"
    "tk"
    "base-devel"
)

# -------------------------------------------------------
# Install packages using yay
# -------------------------------------------------------

for package in "${packages[@]}"; do
    if pacman -Qq "$package" &> /dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package..."
        yay -S --noconfirm "$package"
    fi
done
echo "All required packages are installed!"

# install pyenv:
curl https://pyenv.run | bash

# Ensure pipx path
pipx ensurepath

# Set up Rust if not installed
if ! command -v rustc &> /dev/null; then
    echo "Rust is not installed. Installing via rustup..."
    rustup install stable
    rustup default stable
    echo "Rust installed and configured."
else
    echo "Rust is already installed."
fi
