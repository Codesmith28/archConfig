#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Bootstrap Master Runner
# ==============================================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing Arch Linux packages..."
if [ -f "$DIR/packages/installPackages.sh" ]; then
    bash "$DIR/packages/installPackages.sh"
fi

echo "==> Setting up systemd services and hardware optimizations..."
if [ -f "$DIR/setup_scripts/setup.sh" ]; then
    (cd "$DIR/setup_scripts" && bash setup.sh)
fi
