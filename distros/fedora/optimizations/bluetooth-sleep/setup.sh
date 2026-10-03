#!/usr/bin/env bash
# ==============================================================================
# Bluetooth Clean Sleep Hook Setup
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DEST="${1:-/usr/lib/systemd/system-sleep}"

echo "Installing bluetooth-sleep hook to $HOOK_DEST..."
sudo mkdir -p "$HOOK_DEST"
sudo cp "$SCRIPT_DIR/bluetooth-sleep.sh" "$HOOK_DEST/bluetooth-sleep.sh"
sudo chmod +x "$HOOK_DEST/bluetooth-sleep.sh"

echo "Bluetooth sleep hook installed successfully."
