#!/usr/bin/env bash
# ==============================================================================
# Screen Brightness Controller with OSD Feedback
# Supports brightnessctl, light, and direct sysfs fallback
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_PROGRESS="$SCRIPT_DIR/notify-progress.sh"
if [[ ! -x "$NOTIFY_PROGRESS" && -x "$HOME/.config/hypr/scripts/notify-progress.sh" ]]; then
    NOTIFY_PROGRESS="$HOME/.config/hypr/scripts/notify-progress.sh"
fi

ACTION="${1:-status}"

adjust_brightness() {
    local act="$1"
    if command -v brightnessctl >/dev/null 2>&1; then
        case "$act" in
            +|up|5%+|+5%)
                brightnessctl -q set 5%+ 2>/dev/null || true
                ;;
            -|down|5%-|-5%)
                brightnessctl -q set 5%- 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                brightnessctl -q set "$act" 2>/dev/null || true
                ;;
        esac
    elif command -v light >/dev/null 2>&1; then
        case "$act" in
            +|up|5%+|+5%)
                light -A 5 2>/dev/null || true
                ;;
            -|down|5%-|-5%)
                light -U 5 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                light -S "${act//[^0-9]/}" 2>/dev/null || true
                ;;
        esac
    fi
}

adjust_brightness "$ACTION"

# Query current brightness percentage
BRIGHTNESS=""
if command -v brightnessctl >/dev/null 2>&1; then
    BRIGHTNESS="$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/, "", $4); print $4}' | head -n1 || true)"
elif command -v light >/dev/null 2>&1; then
    raw="$(light -G 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then
        BRIGHTNESS="$(awk -v v="$raw" 'BEGIN { printf "%.0f", v }')"
    fi
elif compgen -G "/sys/class/backlight/*" >/dev/null; then
    dev="$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1 || true)"
    if [[ -n "$dev" && -f "$dev/brightness" && -f "$dev/max_brightness" ]]; then
        cur="$(cat "$dev/brightness" 2>/dev/null || echo 0)"
        max="$(cat "$dev/max_brightness" 2>/dev/null || echo 1)"
        if (( max > 0 )); then
            BRIGHTNESS=$(( cur * 100 / max ))
        fi
    fi
fi

BRIGHTNESS="${BRIGHTNESS//[^0-9]/}"
BRIGHTNESS="${BRIGHTNESS:-100}"
if (( BRIGHTNESS > 100 )); then BRIGHTNESS=100; fi
if (( BRIGHTNESS < 1 )); then BRIGHTNESS=1; fi

if (( BRIGHTNESS < 35 )); then
    ICON="display-brightness-low-symbolic"
elif (( BRIGHTNESS < 70 )); then
    ICON="display-brightness-medium-symbolic"
else
    ICON="display-brightness-high-symbolic"
fi

TITLE="Brightness"
SUBTEXT="Display: Backlight"

if [[ -x "$NOTIFY_PROGRESS" ]]; then
    "$NOTIFY_PROGRESS" "$TITLE" "brightness" "$BRIGHTNESS" "$SUBTEXT" "$ICON" &
elif command -v notify-send >/dev/null 2>&1; then
    notify-send \
        -a "Brightness" \
        -r 999 \
        -h "string:x-canonical-private-synchronous:brightness" \
        -h "int:value:$BRIGHTNESS" \
        -i "$ICON" \
        -t 1200 \
        "$TITLE" \
        "$BRIGHTNESS%" &
fi
