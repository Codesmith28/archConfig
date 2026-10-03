#!/usr/bin/env bash
# ==============================================================================
# archConfig Core Layer Bootstrap Master Runner (macOS & Linux)
#
# Sets up cross-platform core developer dependencies:
# 1. zoxide (smart directory jumping)
# 2. fzf (fuzzy finder)
# ==============================================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Setting up archConfig universal core dependencies..."
if [ -f "$DIR/scripts/setup_shell_dependencies.sh" ]; then
    bash "$DIR/scripts/setup_shell_dependencies.sh" "$@"
fi
