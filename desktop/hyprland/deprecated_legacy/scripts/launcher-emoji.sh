#!/usr/bin/env bash
# ==============================================================================
# Hyprland Emoji Picker Launcher (Legacy fallback)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/launcher-guard.sh" ]]; then
    source "$SCRIPT_DIR/launcher-guard.sh"
    guard_launcher "emoji"
fi

selection=""

# Fallback: Rofi emoji menu
if [[ -x "$HOME/.config/hypr/scripts/rofi-menu.sh" ]]; then
    selection="$("$HOME/.config/hypr/scripts/rofi-menu.sh" emoji "Emoji" -theme-str 'window { width: 24%; } @media ( max-width: 1500 ) { window { width: 29%; } } @media ( max-width: 1100 ) { window { width: 48%; } }' -matching fuzzy 2>/dev/null || true)"
elif command -v rofi >/dev/null 2>&1; then
    selection="$(rofi -show emoji -matching fuzzy 2>/dev/null || true)"
fi

[[ -z "$selection" ]] && exit 0

emoji="${selection%% *}"
[[ -z "$emoji" ]] && exit 0

if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$emoji" | wl-copy
elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$emoji" | xclip -selection clipboard
fi

if command -v wtype >/dev/null 2>&1; then
    sleep 0.1
    wtype "$emoji" 2>/dev/null || true
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Emoji Picker" "Emoji Copied" "$emoji" 2>/dev/null || true
fi
