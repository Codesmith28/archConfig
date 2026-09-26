#!/usr/bin/env bash
# Ubuntu Bootstrap Master Runner
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Setting up Ubuntu optimizations..."
if [ -f "$DIR/optimizations/setup.sh" ]; then
    bash "$DIR/optimizations/setup.sh"
fi
echo "==> Setting up systemd services..."
if [ -f "$DIR/setup_scripts/setup.sh" ]; then
    (cd "$DIR/setup_scripts" && bash setup.sh)
fi
