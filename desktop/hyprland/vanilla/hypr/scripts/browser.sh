#!/usr/bin/env bash
# ==============================================================================
# Default Web Browser Resolver for Hyprland
# ==============================================================================
# Dynamically opens the system / GNOME default browser via xdg-open, gio open,
# or user default-web-browser setting, with standalone fallbacks.
# ==============================================================================
set -euo pipefail

TARGET="${1:-https://duckduckgo.com}"

# 1. Resolve configured default browser via xdg-settings
if command -v xdg-settings >/dev/null 2>&1; then
    DEF_BROWSER="$(xdg-settings get default-web-browser 2>/dev/null || true)"
    if [[ -n "$DEF_BROWSER" ]]; then
        # Strip .desktop extension
        BIN_NAME="${DEF_BROWSER%.desktop}"
        BIN_NAME="${BIN_NAME##*.}" # e.g. org.mozilla.firefox -> firefox
        if command -v "$BIN_NAME" >/dev/null 2>&1; then
            exec "$BIN_NAME" "$@"
        fi
    fi
fi

# 2. Use gio open / xdg-open for system default browser
if command -v gio >/dev/null 2>&1; then
    exec gio open "$TARGET"
elif command -v xdg-open >/dev/null 2>&1; then
    exec xdg-open "$TARGET"
fi

# 3. Direct browser candidates fallback
for b in firefox zen-browser zen google-chrome-stable google-chrome chromium epiphany brave-browser; do
    if command -v "$b" >/dev/null 2>&1; then
        exec "$b" "$@"
    fi
done

echo "Error: No supported web browser found." >&2
exit 1
