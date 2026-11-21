#!/usr/bin/env bash
# ==============================================================================
# setup-hyprland-on-fedora-gnome.sh
# Dedicated setup for installing Hyprland on top of Fedora GNOME (fedora-gnome only)
# ==============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"

DRY_RUN=false
NON_INTERACTIVE=false
FORWARD_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            FORWARD_ARGS+=("$arg")
            ;;
        --non-interactive|-y)
            NON_INTERACTIVE=true
            FORWARD_ARGS+=("$arg")
            ;;
        -h|--help)
            echo "Usage: ./distros/fedora/setup-hyprland-on-fedora-gnome.sh [OPTIONS]"
            echo ""
            echo "Options:"
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

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "  (dry-run) Would run: $*"
    else
        if [ "$EUID" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            "$@"
        fi
    fi
}

is_fedora() {
    if [ -f /etc/fedora-release ]; then
        return 0
    fi
    if [ -f /etc/os-release ] && grep -qi "^ID=.*fedora" /etc/os-release; then
        return 0
    fi
    return 1
}

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

is_gnome_env() {
    local raw_de="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
    local de_lower
    de_lower="$(echo "$raw_de" | tr '[:upper:]' '[:lower:]')"

    if echo "$de_lower" | grep -q "gnome"; then
        return 0
    fi

    local current_de_detected
    current_de_detected="$(detect_de)"
    if [ "$current_de_detected" = "gnome" ]; then
        return 0
    fi

    # Also accept if current session is Hyprland on a fedora-gnome base installation
    if [ "$current_de_detected" = "hyprland" ] && { [ -f /usr/share/wayland-sessions/gnome.desktop ] || [ -f /usr/share/xsessions/gnome.desktop ] || pgrep -x "gnome-shell" >/dev/null 2>&1; }; then
        return 0
    fi

    return 1
}

verify_fedora_gnome_requirement() {
    if ! is_fedora; then
        echo "❌ [ERROR] Hyprland installation is strictly supported only on Fedora. Detected host OS is not Fedora." >&2
        echo "   Aborting: archConfig Hyprland support on RPM-based systems is tailored specifically for Fedora." >&2
        exit 1
    fi

    if ! is_gnome_env; then
        local detected_de_val
        detected_de_val="$(detect_de)"
        echo "❌ [ERROR] Hyprland installation is strictly supported only from fedora-gnome." >&2
        echo "   Current desktop environment detected: '$detected_de_val' (session: '${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-none}}')." >&2
        echo "   Aborting: Hyprland requires Fedora Workstation (GNOME) as the parent desktop environment." >&2
        exit 1
    fi
}

# Strictly verify fedora-gnome requirement before taking any action
verify_fedora_gnome_requirement

echo "==> Verified environment: Fedora GNOME base installation detected."
echo "==> Enabling lionheartp/Hyprland COPR repository..."
run_cmd dnf copr enable -y lionheartp/Hyprland

echo "==> Installing Hyprland and desktop packages via dnf..."
run_cmd dnf install -y hyprland xdg-desktop-portal-hyprland hyprpolkitagent waybar hyprland-guiutils hyprlauncher blueman hyprlock hypridle pavucontrol hyprshot quickshell

if [ -f "$REPO_DIR/desktop/hyprland/setup.sh" ]; then
    echo "==> Dispatching to Hyprland desktop layer setup..."
    bash "$REPO_DIR/desktop/hyprland/setup.sh" "${FORWARD_ARGS[@]}"
fi

echo "==> Hyprland setup on Fedora GNOME completed successfully!"
