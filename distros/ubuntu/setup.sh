#!/usr/bin/env bash
# Ubuntu Bootstrap Master Runner
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"

echo "==> Setting up Ubuntu optimizations..."
if [ -f "$DIR/optimizations/setup.sh" ]; then
    bash "$DIR/optimizations/setup.sh"
fi

# Run universal Linux hardware optimizations (battery, usb-wake, bluetooth-sleep, rog-nvidia)
if [ -f "$REPO_DIR/hardware-linux/setup.sh" ]; then
    echo "==> Setting up Linux hardware optimizations..."
    bash "$REPO_DIR/hardware-linux/setup.sh" "$@"
fi

echo "==> Setting up systemd services..."
if [ -f "$DIR/setup_scripts/setup.sh" ]; then
    (cd "$DIR/setup_scripts" && bash setup.sh)
fi
