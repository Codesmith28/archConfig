#!/usr/bin/env bash
# ==============================================================================
# Ubuntu Machine Setup & Synchronization Master Script
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 1. Syncing dotfiles and configuration symlinks..."
bash "$SCRIPT_DIR/dotfiles/sync.sh"

echo "==> 2. Refreshing font cache..."
fc-cache -f

echo "==> 3. Applying GNOME desktop keybindings & Ptyxis terminal shortcuts..."
bash "$SCRIPT_DIR/optimizations/optimize_gnome/config.sh"

echo "==> 4. Checking CLI tools..."
mkdir -p "$HOME/.local/bin"

if ! command -v eza >/dev/null 2>&1; then
    echo "    Installing eza into ~/.local/bin..."
    wget -q -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz -C "$HOME/.local/bin"
    chmod +x "$HOME/.local/bin/eza"
fi

if ! command -v starship >/dev/null 2>&1; then
    echo "    Installing starship into ~/.local/bin..."
    curl -sS https://starship.rs/install.sh | sh -s -- -b "$HOME/.local/bin" -y
fi

if ! command -v lazygit >/dev/null 2>&1; then
    echo "    Installing lazygit into ~/.local/bin..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" | tar xz -C "$HOME/.local/bin" lazygit
    chmod +x "$HOME/.local/bin/lazygit"
fi

echo "==> 5. System optimizations..."
if [[ -f "$SCRIPT_DIR/optimizations/setup.sh" ]]; then
    if [[ "$(id -u)" -eq 0 ]] || sudo -n true 2>/dev/null; then
        sudo bash "$SCRIPT_DIR/optimizations/setup.sh"
    else
        echo "    Note: Hardware & systemd optimizations require sudo privileges."
        echo "    To configure battery limits, NVIDIA suspend hooks, and USB wake isolation, run:"
        echo "    sudo bash $SCRIPT_DIR/optimizations/setup.sh"
    fi
fi

echo ""
echo "✨ Synchronization complete! Open a new terminal tab or window to start."
