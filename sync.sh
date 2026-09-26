#!/usr/bin/env bash
# ==============================================================================
# archConfig Universal Cross-Distro Dotfile Synchronizer
# ==============================================================================
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
TARGET_DISTRO=""
TARGET_DE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --distro)
            TARGET_DISTRO="$2"
            shift 2
            ;;
        --de)
            TARGET_DE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: ./sync.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run            Show what symlinks would be created without making changes"
            echo "  --distro <name>      Override distro (fedora, arch, ubuntu, ubuntu_server, mac, omarchy)"
            echo "  --de <name>          Override desktop environment (gnome, kde, hyprland, none)"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ------------------------------------------------------------------------------
# 1. Environment & OS Detection
# ------------------------------------------------------------------------------
detect_os() {
    if [ -n "$TARGET_DISTRO" ]; then
        echo "$TARGET_DISTRO"
        return
    fi

    if [ "$(uname -s)" = "Darwin" ]; then
        echo "mac"
    elif [ -f /etc/fedora-release ]; then
        echo "fedora"
    elif [ -f /etc/arch-release ]; then
        if grep -qi "omarchy" /etc/os-release 2>/dev/null; then
            echo "omarchy"
        else
            echo "arch"
        fi
    elif grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
        if [ -n "$SSH_CONNECTION" ] && ! command -v Xorg >/dev/null 2>&1 && ! command -v wayland-scanner >/dev/null 2>&1; then
            echo "ubuntu_server"
        else
            echo "ubuntu"
        fi
    else
        echo "generic"
    fi
}

detect_de() {
    if [ -n "$TARGET_DE" ]; then
        echo "$TARGET_DE"
        return
    fi

    local current_de="${XDG_CURRENT_DESKTOP:-$DESKTOP_SESSION}"
    current_de=$(echo "$current_de" | tr '[:upper:]' '[:lower:]')

    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || echo "$current_de" | grep -q "hyprland"; then
        echo "hyprland"
    elif echo "$current_de" | grep -q "gnome"; then
        echo "gnome"
    elif echo "$current_de" | grep -qE "kde|plasma"; then
        echo "kde"
    elif [ "$(uname -s)" = "Darwin" ]; then
        echo "mac_desktop"
    else
        echo "none"
    fi
}

DETECTED_OS="$(detect_os)"
DETECTED_DE="$(detect_de)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 archConfig Cross-Distro Synchronizer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  • Operating System   : $DETECTED_OS"
echo "  • Desktop Environment: $DETECTED_DE"
echo "  • Repository Root    : $REPO_DIR"
[ "$DRY_RUN" = true ] && echo "  • Mode               : DRY RUN (no modifications)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ------------------------------------------------------------------------------
# 2. Safe Symlink Helper
# ------------------------------------------------------------------------------
link_item() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ]; then
        local raw_target
        raw_target="$(readlink "$dest" 2>/dev/null || true)"
        if [ "$raw_target" = "$src" ]; then
            echo "  ✓ Already linked: $dest"
            return 0
        fi
        echo "  ↻ Updating symlink: $dest -> $src"
        if [ "$DRY_RUN" = false ]; then
            rm -f "$dest"
            ln -snf "$src" "$dest"
        fi
        return 0
    fi

    if [ -e "$dest" ]; then
        echo "  ⚠ Backing up existing $dest -> ${dest}.bak"
        if [ "$DRY_RUN" = false ]; then
            rm -rf "${dest}.bak"
            mv "$dest" "${dest}.bak"
        fi
    fi

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$(dirname "$dest")"
        ln -snf "$src" "$dest"
    fi
    echo "  → Linked: $dest -> $src"
}

# ------------------------------------------------------------------------------
# 3. Synchronize Core Configurations (~/.config/)
# ------------------------------------------------------------------------------
echo ""
echo "==> Synchronizing Core Application Configs (~/.config/)..."
mkdir -p "$HOME/.config"

for item in "$REPO_DIR/core/config"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    link_item "$item" "$HOME/.config/$name"
done

# ------------------------------------------------------------------------------
# 4. Synchronize Core Home Dotfiles (~/.*)
# ------------------------------------------------------------------------------
echo ""
echo "==> Synchronizing Home Dotfiles (~/)..."
for item in "$REPO_DIR/core/home"/.* "$REPO_DIR/core/home"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    [ "$name" = "." ] && continue
    [ "$name" = ".." ] && continue
    [ "$name" = "*" ] && continue
    link_item "$item" "$HOME/$name"
done

# ------------------------------------------------------------------------------
# 5. Apply Desktop Environment Layer (if applicable)
# ------------------------------------------------------------------------------
if [ "$DETECTED_DE" = "gnome" ]; then
    echo ""
    echo "==> Applying GNOME Desktop Layer..."
    if [ -f "$REPO_DIR/desktop/gnome/setup.sh" ]; then
        echo "  Tip: Run '$REPO_DIR/desktop/gnome/setup.sh' to install GNOME extensions & dconf keybindings."
    fi
elif [ "$DETECTED_DE" = "kde" ]; then
    echo ""
    echo "==> Applying KDE Plasma Layer..."
    if [ -f "$REPO_DIR/desktop/kde/setup.sh" ]; then
        bash "$REPO_DIR/desktop/kde/setup.sh"
    fi
elif [ "$DETECTED_DE" = "hyprland" ]; then
    echo ""
    echo "==> Applying Hyprland Wayland Layer..."
    # If omarchy, use modern lua setup, otherwise classic
    if [ "$DETECTED_OS" = "omarchy" ]; then
        link_item "$REPO_DIR/desktop/hyprland/lua" "$HOME/.config/hypr"
    else
        link_item "$REPO_DIR/desktop/hyprland/classic" "$HOME/.config/hypr"
    fi
    link_item "$REPO_DIR/desktop/hyprland/waybar" "$HOME/.config/waybar"
    link_item "$REPO_DIR/desktop/hyprland/rofi" "$HOME/.config/rofi"
    link_item "$REPO_DIR/desktop/hyprland/swaync" "$HOME/.config/swaync"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ All configurations synchronized successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
