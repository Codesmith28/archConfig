#!/usr/bin/env bash
# ==============================================================================
# Bluetooth Manager Launcher
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" =~ ^(-s|--status|status)$ ]]; then
    exec "$SCRIPT_DIR/bluetooth-status.sh" "${@:2}"
fi

# Singleton check: if bluetooth manager is already running, focus it and do not spawn duplicate
if pgrep -f "bluetoothctl|bluetuith|bluetui|blueman" >/dev/null 2>&1; then
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch focuswindow "title:bluetooth" 2>/dev/null || \
        hyprctl dispatch focuswindow "class:blueman-manager" 2>/dev/null || true
    fi
    exit 0
fi

# Prefer native GUI blueman-manager if installed
if command -v blueman-manager >/dev/null 2>&1; then
    exec blueman-manager
elif command -v bluetuith >/dev/null 2>&1; then
    if command -v ghostty >/dev/null 2>&1; then
        exec ghostty --class=small_float --title=bluetuith -e bluetuith
    else
        exec bluetuith
    fi
elif command -v bluetui >/dev/null 2>&1; then
    if command -v ghostty >/dev/null 2>&1; then
        exec ghostty --class=small_float --title=bluetui -e bluetui
    else
        exec bluetui
    fi
else
    if command -v ghostty >/dev/null 2>&1; then
        exec ghostty --class=small_float --title=bluetoothctl -e bluetoothctl
    elif command -v ptyxis >/dev/null 2>&1; then
        exec ptyxis --title=bluetoothctl -- bluetoothctl
    else
        exec bluetoothctl
    fi
fi
