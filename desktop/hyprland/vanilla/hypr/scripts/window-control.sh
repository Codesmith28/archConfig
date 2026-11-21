#!/usr/bin/env bash
# ==============================================================================
# GNOME-Aligned Window Control Helper for Hyprland
# Super+Up (Maximize), Super+Down (Restore), Super+Left/Right (Snap/Tile), Super+H (Minimize)
# ==============================================================================
set -euo pipefail

# 1. Ensure runtime environment
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

dispatch() {
    local lua_expr="$1"
    local classic_cmd="$2"
    local out
    out="$(hyprctl dispatch "$lua_expr" 2>&1 || true)"
    if [[ "$out" == *"error"* ]] && [[ -n "$classic_cmd" ]]; then
        hyprctl dispatch $classic_cmd 2>/dev/null || true
    fi
}

ACTION="${1:-maximize}"

ACTIVE_JSON="$(hyprctl activewindow -j 2>/dev/null || echo "{}")"
if ! echo "$ACTIVE_JSON" | jq . >/dev/null 2>&1; then
    ACTIVE_JSON="{}"
fi

IS_FULLSCREEN="$(echo "$ACTIVE_JSON" | jq -r '.fullscreen // 0')"
IS_FLOATING="$(echo "$ACTIVE_JSON" | jq -r '.floating // false')"

case "$ACTION" in
    maximize|max)
        # Super+Up in GNOME: Toggle maximize (fullscreen type 1)
        dispatch "hl.dsp.window.fullscreen({ action = 'toggle', type = 1 })" "fullscreen 1"
        ;;

    restore|unmax)
        # Super+Down in GNOME: Restore from maximize / unfloat
        if [ "$IS_FULLSCREEN" -ne 0 ]; then
            dispatch "hl.dsp.window.fullscreen({ action = 'unset' })" "fullscreen 0"
        elif [ "$IS_FLOATING" = "true" ]; then
            dispatch "hl.dsp.window.float({ action = 'off' })" "togglefloating 0"
        else
            # If tiled and not maximized, float to medium preset
            dispatch "hl.dsp.window.float({ action = 'on' })" "togglefloating 1"
            dispatch "hl.dsp.window.resize({ x = 960, y = 600, exact = true })" "resizeactive exact 960 600"
            dispatch "hl.dsp.window.center()" "centerwindow"
        fi
        ;;

    snap-left|left)
        # Super+Left: Snap / move left
        dispatch "hl.dsp.window.move({ direction = 'left' })" "movewindow l"
        ;;

    snap-right|right)
        # Super+Right: Snap / move right
        dispatch "hl.dsp.window.move({ direction = 'right' })" "movewindow r"
        ;;

    minimize|hide)
        # Super+H in GNOME: Minimize window (move to special:minimized)
        dispatch "hl.dsp.window.move({ workspace = 'special:minimized' })" "movetoworkspacesilent special:minimized"
        ;;
esac

exit 0
