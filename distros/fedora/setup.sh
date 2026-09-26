#!/usr/bin/env bash
# Fedora Bootstrap Master Runner
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Setting up Fedora optimizations..."
if [ -f "$DIR/optimizations/setup.sh" ]; then
    bash "$DIR/optimizations/setup.sh"
fi
