#!/usr/bin/env bash
# ==============================================================================
# macOS Bootstrap Master Runner
# ==============================================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing macOS Homebrew packages and casks..."
if [ -f "$DIR/packages/installPackages.sh" ]; then
    (cd "$DIR/packages" && bash installPackages.sh)
fi
