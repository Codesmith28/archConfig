#!/usr/bin/env bash
# ==============================================================================
# Dynamic Window Float Sizing & Cycling Utility for Hyprland
# Supports Small (680x440), Medium (960x600), and Big (1200x780) float presets
# Dual Lua / Classic Dispatcher Protocol for Universal Hyprland Compatibility
# ==============================================================================
set -euo pipefail

# 1. Ensure runtime environment and sockets
if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    latest_sig="$(ls -td "$XDG_RUNTIME_DIR"/hypr/* 2>/dev/null | head -n1 | xargs -r basename || true)"
    if [[ -n "$latest_sig" ]]; then
        export HYPRLAND_INSTANCE_SIGNATURE="$latest_sig"
    fi
fi

if [[ -z "${WAYLAND_DISPLAY:-}" ]] || [[ ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]; then
    for s in "$XDG_RUNTIME_DIR"/wayland-[0-9]*; do
        if [[ -S "$s" ]]; then
            export WAYLAND_DISPLAY="$(basename "$s")"
            break
        fi
    done
fi

if ! command -v hyprctl >/dev/null 2>&1; then
    exit 0
fi

# 2. Dimensions
SMALL_W=680
SMALL_H=440
MEDIUM_W=960
MEDIUM_H=600
LARGE_W=1200
LARGE_H=780

MODE="${1:-cycle}"
case "$MODE" in
    small|--small)               MODE="small" ;;
    medium|mid|--medium|--mid)   MODE="medium" ;;
    big|large|--big|--large)     MODE="big" ;;
    toggle|--toggle)             MODE="toggle" ;;
    cycle|--cycle|*)             MODE="cycle" ;;
esac

# 3. Dual Dispatcher Function
dispatch() {
    local lua_expr="$1"
    local classic_cmd="$2"
    local out
    out="$(hyprctl dispatch "$lua_expr" 2>&1 || true)"
    if [[ "$out" == *"error"* ]] && [[ -n "$classic_cmd" ]]; then
        hyprctl dispatch $classic_cmd 2>/dev/null || true
    fi
}

notify_preset() {
    local label="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -h "string:x-canonical-private-synchronous:window-float" \
            -t 900 -r 996 "Window Preset" "$label" 2>/dev/null || true
    fi
}

# 4. Fetch Active Window State
ACTIVE_JSON="$(hyprctl activewindow -j 2>/dev/null || echo "{}")"
if ! echo "$ACTIVE_JSON" | jq . >/dev/null 2>&1; then
    ACTIVE_JSON="{}"
fi

IS_FLOATING="$(echo "$ACTIVE_JSON" | jq -r '.floating // false')"
CURRENT_WIDTH="$(echo "$ACTIVE_JSON" | jq -r '.size[0] // 0')"

case "$MODE" in
    small)
        dispatch "hl.dsp.window.float({ action = 'on' })" "togglefloating 1"
        dispatch "hl.dsp.window.resize({ x = $SMALL_W, y = $SMALL_H, exact = true })" "resizeactive exact $SMALL_W $SMALL_H"
        dispatch "hl.dsp.window.center()" "centerwindow"
        notify_preset "Small Float ($SMALL_W × $SMALL_H)"
        ;;

    medium)
        dispatch "hl.dsp.window.float({ action = 'on' })" "togglefloating 1"
        dispatch "hl.dsp.window.resize({ x = $MEDIUM_W, y = $MEDIUM_H, exact = true })" "resizeactive exact $MEDIUM_W $MEDIUM_H"
        dispatch "hl.dsp.window.center()" "centerwindow"
        notify_preset "Medium Float ($MEDIUM_W × $MEDIUM_H)"
        ;;

    big)
        dispatch "hl.dsp.window.float({ action = 'on' })" "togglefloating 1"
        dispatch "hl.dsp.window.resize({ x = $LARGE_W, y = $LARGE_H, exact = true })" "resizeactive exact $LARGE_W $LARGE_H"
        dispatch "hl.dsp.window.center()" "centerwindow"
        notify_preset "Big Float ($LARGE_W × $LARGE_H)"
        ;;

    toggle)
        dispatch "hl.dsp.window.float({ action = 'toggle' })" "togglefloating"
        ;;

    cycle)
        if [ "$IS_FLOATING" = "false" ]; then
            # Currently tiled -> Float at Small size
            dispatch "hl.dsp.window.float({ action = 'on' })" "togglefloating 1"
            dispatch "hl.dsp.window.resize({ x = $SMALL_W, y = $SMALL_H, exact = true })" "resizeactive exact $SMALL_W $SMALL_H"
            notify_preset "Small Float ($SMALL_W × $SMALL_H)"
        else
            # Currently floating -> cycle through Medium -> Big -> Small
            if [ "$CURRENT_WIDTH" -lt 820 ]; then
                dispatch "hl.dsp.window.resize({ x = $MEDIUM_W, y = $MEDIUM_H, exact = true })" "resizeactive exact $MEDIUM_W $MEDIUM_H"
                notify_preset "Medium Float ($MEDIUM_W × $MEDIUM_H)"
            elif [ "$CURRENT_WIDTH" -lt 1080 ]; then
                dispatch "hl.dsp.window.resize({ x = $LARGE_W, y = $LARGE_H, exact = true })" "resizeactive exact $LARGE_W $LARGE_H"
                notify_preset "Big Float ($LARGE_W × $LARGE_H)"
            else
                dispatch "hl.dsp.window.resize({ x = $SMALL_W, y = $SMALL_H, exact = true })" "resizeactive exact $SMALL_W $SMALL_H"
                notify_preset "Small Float ($SMALL_W × $SMALL_H)"
            fi
        fi
        dispatch "hl.dsp.window.center()" "centerwindow"
        ;;
esac

exit 0
