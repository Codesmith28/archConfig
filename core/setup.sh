#!/usr/bin/env bash
# ==============================================================================
# archConfig Core Layer Bootstrap Master Runner (macOS & Linux)
#
# Sets up cross-platform core developer dependencies:
# (starship, leaf, zoxide, fzf, herdr, lazydocker, lazygit, uv, yazi, eza, fastfetch)
# ==============================================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Setting up archConfig universal core dependencies..."
if [ -f "$DIR/scripts/setup_shell_dependencies.sh" ]; then
    bash "$DIR/scripts/setup_shell_dependencies.sh" "$@"
fi
