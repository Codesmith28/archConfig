#!/usr/bin/env bash
# ==============================================================================
# Fedora Bootstrap Master Runner
# ==============================================================================
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"

echo "==> Setting up Fedora hardware and system optimizations..."
if [ -f "$DIR/optimizations/setup.sh" ]; then
    bash "$DIR/optimizations/setup.sh" "$@"
fi

# Detect desktop environment and dispatch to desktop layer (SKILL.md Rule 3)
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

DETECTED_DE="$(detect_de)"
echo "==> Detected Desktop Environment: $DETECTED_DE"

# Distro optimizations setup already invokes optimize_kde / optimize_gnome if available.
# As a failsafe, ensure the desktop setup was applied:
if [ "$DETECTED_DE" = "kde" ] && [ -f "$REPO_DIR/desktop/kde/setup.sh" ]; then
    echo "==> Ensuring KDE Plasma desktop layer is fully synchronized..."
    bash "$REPO_DIR/desktop/kde/setup.sh" "$@"
elif [ "$DETECTED_DE" = "gnome" ] && [ -f "$REPO_DIR/desktop/gnome/setup.sh" ]; then
    echo "==> Ensuring GNOME desktop layer is fully synchronized..."
    bash "$REPO_DIR/desktop/gnome/setup.sh" "$@"
elif [ "$DETECTED_DE" = "hyprland" ]; then
    echo "==> Hyprland detected. Synchronize via: ./sync.sh --de hyprland"
fi
