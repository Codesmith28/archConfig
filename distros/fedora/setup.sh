#!/usr/bin/env bash
# ==============================================================================
# Fedora Bootstrap Master Runner
# Supports: Fedora Workstation (GNOME), KDE Plasma, and optional Hyprland
# ==============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"

INSTALL_HYPRLAND=false
RUN_ALL=false
DRY_RUN=false
NON_INTERACTIVE=false
FORWARD_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --install-hyprland|--hyprland)
            INSTALL_HYPRLAND=true
            ;;
        --all)
            RUN_ALL=true
            ;;
        --dry-run)
            DRY_RUN=true
            FORWARD_ARGS+=("$arg")
            ;;
        --non-interactive|-y)
            NON_INTERACTIVE=true
            FORWARD_ARGS+=("$arg")
            ;;
        -h|--help)
            echo "Usage: ./distros/fedora/setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --install-hyprland    Install optional Hyprland desktop via setup-hyprland-on-fedora-gnome.sh"
            echo "  --all                 Run full Fedora bootstrap in addition to Hyprland installation"
            echo "  --dry-run             Show actions without executing changes"
            echo "  --non-interactive, -y Assume yes for package installation and skip prompts"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            FORWARD_ARGS+=("$arg")
            ;;
    esac
done

detect_de() {
    local current_de="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
    current_de=$(echo "$current_de" | tr '[:upper:]' '[:lower:]')

    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || echo "$current_de" | grep -q "hyprland" || pgrep -x "Hyprland" >/dev/null 2>&1; then
        echo "hyprland"
    elif echo "$current_de" | grep -q "gnome" || pgrep -x "gnome-shell" >/dev/null 2>&1; then
        echo "gnome"
    elif echo "$current_de" | grep -qE "kde|plasma" || [ -n "${KDE_FULL_SESSION:-}" ] || [ -n "${KDE_SESSION_VERSION:-}" ] || pgrep -x "plasmashell" >/dev/null 2>&1 || pgrep -x "kwin_wayland" >/dev/null 2>&1 || pgrep -x "kwin_x11" >/dev/null 2>&1; then
        echo "kde"
    elif [ -f /usr/share/wayland-sessions/plasmawayland.desktop ] || [ -f /usr/share/wayland-sessions/plasma.desktop ]; then
        echo "kde"
    elif [ -f /usr/share/wayland-sessions/gnome.desktop ]; then
        echo "gnome"
    else
        echo "none"
    fi
}

# When invoked with --install-hyprland as a separate/optional setup without --all:
# Delegate directly to setup-hyprland-on-fedora-gnome.sh and exit.
if [ "$INSTALL_HYPRLAND" = true ] && [ "$RUN_ALL" = false ]; then
    exec bash "$DIR/setup-hyprland-on-fedora-gnome.sh" "${FORWARD_ARGS[@]}"
fi

echo "==> Setting up essential packages..."
if [ -f "$REPO_DIR/distros/common/setup_packages.sh" ]; then
    bash "$REPO_DIR/distros/common/setup_packages.sh" "${FORWARD_ARGS[@]}"
fi

echo "==> Setting up Fedora hardware and system optimizations..."
if [ -f "$DIR/optimizations/setup.sh" ]; then
    bash "$DIR/optimizations/setup.sh" "${FORWARD_ARGS[@]}"
fi

# Run universal Linux hardware optimizations (battery, usb-wake, bluetooth, rog-nvidia)
if [ -f "$REPO_DIR/hardware-linux/setup.sh" ]; then
    echo "==> Setting up Linux hardware optimizations..."
    bash "$REPO_DIR/hardware-linux/setup.sh" "${FORWARD_ARGS[@]}"
fi

DETECTED_DE="$(detect_de)"
echo "==> Detected Desktop Environment: $DETECTED_DE"

# Dispatch to desktop layer
if [ "$INSTALL_HYPRLAND" = true ]; then
    bash "$DIR/setup-hyprland-on-fedora-gnome.sh" "${FORWARD_ARGS[@]}"
else
    # Distro optimizations setup already invokes optimize_kde / optimize_gnome if available.
    # As a failsafe, ensure the desktop setup was applied:
    if [ "$DETECTED_DE" = "kde" ] && [ -f "$REPO_DIR/desktop/kde/setup.sh" ]; then
        echo "==> Ensuring KDE Plasma desktop layer is fully synchronized..."
        bash "$REPO_DIR/desktop/kde/setup.sh" "${FORWARD_ARGS[@]}"
    elif [ "$DETECTED_DE" = "gnome" ] && [ -f "$REPO_DIR/desktop/gnome/setup.sh" ]; then
        echo "==> Ensuring GNOME desktop layer is fully synchronized..."
        bash "$REPO_DIR/desktop/gnome/setup.sh" "${FORWARD_ARGS[@]}"

        # If running interactively without flags on fedora-gnome, offer optional Hyprland install
        if [ "$NON_INTERACTIVE" = false ] && [ "$DRY_RUN" = false ] && [ -t 0 ]; then
            echo ""
            echo "==> Optional Hyprland Desktop Setup (fedora-gnome):"
            read -rp "  Would you like to install optional Hyprland desktop on top of Fedora GNOME? [y/N]: " _choice || true
            case "${_choice:-}" in
                [yY]|[yY][eE][sS])
                    bash "$DIR/setup-hyprland-on-fedora-gnome.sh" "${FORWARD_ARGS[@]}"
                    ;;
                *)
                    echo "  ⏭️ Skipping optional Hyprland setup."
                    ;;
            esac
        fi
    elif [ "$DETECTED_DE" = "hyprland" ]; then
        if [ -f "$REPO_DIR/desktop/hyprland/setup.sh" ]; then
            echo "==> Ensuring Hyprland desktop layer is fully synchronized..."
            bash "$REPO_DIR/desktop/hyprland/setup.sh" "${FORWARD_ARGS[@]}"
        else
            echo "==> Hyprland detected. Synchronize via: ./sync.sh --de hyprland"
        fi
    fi
fi
