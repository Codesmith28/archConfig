#!/bin/bash

cat <<"EOF"
      _            _
  __| | ___   ___| | _____ _ __
 / _` |/ _ \ / __| |/ / _ \ '__|
| (_| | (_) | (__|   <  __/ |
 \__,_|\___/ \___|_|\_\___|_|

EOF

echo "Preparing to setup Docker for Mac..."

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Please install it first from https://brew.sh"
    exit 1
fi

# On macOS, 'docker' (CLI) and 'docker-compose' are usually bundled
# with 'docker' via Homebrew Cask (Docker Desktop)
packages=(
    "docker"
)

for package in "${packages[@]}"; do
    if brew list --cask "$package" &>/dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package via Homebrew Cask..."
        brew install --cask "$package"
    fi
done

echo "All required packages are installed!"

# macOS does not use systemctl. We just need to open the app.
echo "Starting Docker Desktop..."
open /Applications/Docker.app

echo "Docker setup complete!"
echo "Note: Follow the on-screen instructions in the Docker Desktop UI to finish initialization."
