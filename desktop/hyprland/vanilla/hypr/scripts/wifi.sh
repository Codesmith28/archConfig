#!/usr/bin/env bash
# ==============================================================================
# Wi-Fi / Network Connection Manager Launcher
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" =~ ^(-s|--status|status)$ ]]; then
    exec "$SCRIPT_DIR/wifi-status.sh" "${@:2}"
fi

# Singleton check: if nmtui is already running, focus it and do not spawn duplicate
if pgrep -f "nmtui" >/dev/null 2>&1; then
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch focuswindow "title:nmtui" 2>/dev/null || true
    fi
    exit 0
fi

# Prefer Ghostty with small_float class and nmtui title
if command -v ghostty >/dev/null 2>&1; then
    exec ghostty --class=small_float --title=nmtui -e nmtui
elif command -v ptyxis >/dev/null 2>&1; then
    exec ptyxis --title=nmtui -- nmtui
elif command -v gnome-terminal >/dev/null 2>&1; then
    exec gnome-terminal --title=nmtui -- nmtui
elif command -v nm-connection-editor >/dev/null 2>&1; then
    exec nm-connection-editor
else
    exec nmtui
fi
