#!/usr/bin/env bash
# OmArchy Bootstrap Master Runner
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"


# Run universal Linux hardware optimizations (battery, usb-wake, bluetooth-sleep, rog-nvidia)
if [ -f "$REPO_DIR/hardware-linux/setup.sh" ]; then
    echo "==> Setting up Linux hardware optimizations..."
    bash "$REPO_DIR/hardware-linux/setup.sh" "$@"
fi
