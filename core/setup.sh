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

echo "==> Setting up archConfig universal shell environments (Zsh / Fish)..."
# Non-blocking Zsh environment setup (skipped gracefully if zsh is not installed)
if [ -f "$DIR/scripts/setup_zsh.sh" ]; then
    if command -v zsh >/dev/null 2>&1; then
        bash "$DIR/scripts/setup_zsh.sh" "$@" || {
            echo "  ⚠️ Notice: Zsh setup encountered a non-fatal warning (continuing without blocking)."
        }
    else
        echo "  ℹ️ Notice: 'zsh' is not installed in PATH. Skipping Zsh environment setup (non-blocking)."
    fi
fi

# Non-blocking Fish environment integration (skipped gracefully if fish is not installed)
if command -v fish >/dev/null 2>&1; then
    FISH_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
    if [ -d "$FISH_CONF_DIR" ] && command -v starship >/dev/null 2>&1; then
        FISH_CONF="$FISH_CONF_DIR/config.fish"
        if [ -f "$FISH_CONF" ] && ! grep -q "starship init fish" "$FISH_CONF"; then
            echo -e "\n# Starship Prompt (archConfig)\nstarship init fish | source" >> "$FISH_CONF"
            echo "  ✓ Added Starship prompt integration to $FISH_CONF"
        fi
    fi
fi
