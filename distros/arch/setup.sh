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

# Configure GRUB high-resolution display mode if GRUB is present
if [ -f "$REPO_DIR/troubleshoot/restoreGrub.sh" ] && { command -v grub-mkconfig >/dev/null 2>&1 || [ -f /etc/default/grub ]; }; then
    echo "==> Configuring GRUB high-resolution display mode..."
    bash "$REPO_DIR/troubleshoot/restoreGrub.sh" --config-only "$@" || true
fi

# Run universal Linux hardware optimizations (battery, usb-wake, bluetooth, rog-nvidia)
if [ -f "$REPO_DIR/hardware-linux/setup.sh" ]; then
    echo "==> Setting up Linux hardware optimizations..."
    bash "$REPO_DIR/hardware-linux/setup.sh" "$@"
fi
