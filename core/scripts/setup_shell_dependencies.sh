#!/usr/bin/env bash
# ==============================================================================
# archConfig Universal Shell Dependencies Installer
#
# Installs core shell productivity tools:
# 1. zoxide (smart directory navigation) via official installer into ~/.local/bin
# 2. fzf (fuzzy finder) via GitHub clone into ~/.fzf with non-interactive setup
# ==============================================================================
set -euo pipefail

UPDATE=false

for arg in "$@"; do
    case "$arg" in
        --update|-u)
            UPDATE=true
            ;;
        -h|--help)
            echo "Usage: ./setup_shell_dependencies.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --update, -u   Force re-download / update even if already installed"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🐚 Installing Universal Shell Dependencies (zoxide & fzf)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ------------------------------------------------------------------------------
# 1. zoxide Installation
# ------------------------------------------------------------------------------
echo ""
echo "==> [1/2] Checking zoxide..."
if command -v zoxide >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
    echo "  ✓ zoxide is already installed at $(command -v zoxide) ($(zoxide --version 2>/dev/null || echo 'unknown version'))"
else
    echo "  → Installing / updating zoxide via official install script..."
    if command -v curl >/dev/null 2>&1; then
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    else
        echo "  ❌ Error: Neither curl nor wget was found. Cannot download zoxide." >&2
        exit 1
    fi
    echo "  ✓ zoxide installed successfully."
fi

# ------------------------------------------------------------------------------
# 2. fzf Installation
# ------------------------------------------------------------------------------
echo ""
echo "==> [2/2] Checking fzf..."
FZF_DIR="$HOME/.fzf"

if [ ! -d "$FZF_DIR" ]; then
    echo "  → Cloning fzf repository into $FZF_DIR..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"
elif [ "$UPDATE" = true ]; then
    echo "  → Updating existing fzf repository in $FZF_DIR..."
    git -C "$FZF_DIR" pull --ff-only || true
else
    echo "  ✓ fzf repository already exists at $FZF_DIR"
fi

if [ -x "$FZF_DIR/install" ]; then
    echo "  → Running non-interactive fzf installer (--key-bindings --completion --no-update-rc)..."
    # --key-bindings: enables bindings (CTRL-T, CTRL-R, ALT-C)
    # --completion: enables fuzzy completion
    # --no-update-rc: avoids prompting and modifying shell rc files since archConfig handles sourcing
    "$FZF_DIR/install" --key-bindings --completion --no-update-rc
    echo "  ✓ fzf setup completed."
else
    echo "  ❌ Error: $FZF_DIR/install not found or not executable." >&2
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Shell dependencies installed and configured!"
echo "  • Ensure ~/.local/bin and ~/.fzf/bin are in your PATH (handled by ~/.profile)."
echo "  • Open a new shell or run: source ~/.bashrc (or ~/.zshrc)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
