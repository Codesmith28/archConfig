#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Bootstrap Master Runner
# ==============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"

echo "==> Installing Arch Linux packages..."
if [ -f "$DIR/packages/installPackages.sh" ]; then
    bash "$DIR/packages/installPackages.sh"
fi

echo "==> Setting up systemd services and hardware optimizations..."
if [ -f "$DIR/setup_scripts/setup.sh" ]; then
    (cd "$DIR/setup_scripts" && bash setup.sh)
fi

# Run universal Linux hardware optimizations (battery, usb-wake, bluetooth-sleep, rog-nvidia)
if [ -f "$REPO_DIR/hardware-linux/setup.sh" ]; then
    echo "==> Setting up Linux hardware optimizations..."
    bash "$REPO_DIR/hardware-linux/setup.sh" "$@"
fi
