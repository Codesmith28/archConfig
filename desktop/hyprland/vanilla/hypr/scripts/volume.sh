#!/usr/bin/env bash
# ==============================================================================
# Audio Volume & Mute Controller with OSD Feedback
# Supports PipeWire (wpctl), PulseAudio (pactl), pamixer, and ALSA (amixer)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_PROGRESS="$SCRIPT_DIR/notify-progress.sh"
if [[ ! -x "$NOTIFY_PROGRESS" && -x "$HOME/.config/hypr/scripts/notify-progress.sh" ]]; then
    NOTIFY_PROGRESS="$HOME/.config/hypr/scripts/notify-progress.sh"
fi

ACTION="${1:-status}"

# Helper to execute volume adjustment across available backends
adjust_volume() {
    local act="$1"
    if command -v wpctl >/dev/null 2>&1; then
        case "$act" in
            up|+5%|5%+|+)
                wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null || true
                ;;
            down|-5%|5%-|-)
                wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null || true
                ;;
            mute|toggle-mute|toggle)
                wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "$act" 2>/dev/null || true
                ;;
        esac
    elif command -v pactl >/dev/null 2>&1; then
        case "$act" in
            up|+5%|5%+|+)
                pactl set-sink-volume @DEFAULT_SINK@ +5% 2>/dev/null || true
                ;;
            down|-5%|5%-|-)
                pactl set-sink-volume @DEFAULT_SINK@ -5% 2>/dev/null || true
                ;;
            mute|toggle-mute|toggle)
                pactl set-sink-mute @DEFAULT_SINK@ toggle 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                pactl set-sink-volume @DEFAULT_SINK@ "$act" 2>/dev/null || true
                ;;
        esac
    elif command -v pamixer >/dev/null 2>&1; then
        case "$act" in
            up|+5%|5%+|+)
                pamixer -i 5 2>/dev/null || true
                ;;
            down|-5%|5%-|-)
                pamixer -d 5 2>/dev/null || true
                ;;
            mute|toggle-mute|toggle)
                pamixer -t 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                pamixer --set-volume "${act//[^0-9]/}" 2>/dev/null || true
                ;;
        esac
    elif command -v amixer >/dev/null 2>&1; then
        case "$act" in
            up|+5%|5%+|+)
                amixer -q sset Master 5%+ 2>/dev/null || true
                ;;
            down|-5%|5%-|-)
                amixer -q sset Master 5%- 2>/dev/null || true
                ;;
            mute|toggle-mute|toggle)
                amixer -q sset Master toggle 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                amixer -q sset Master "$act" 2>/dev/null || true
                ;;
        esac
    fi
}

adjust_volume "$ACTION"

# Query current volume and mute status
VOLUME=0
IS_MUTED=false

if command -v wpctl >/dev/null 2>&1; then
    status_out="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
    if [[ -n "$status_out" ]]; then
        if grep -q "MUTED" <<< "$status_out"; then
            IS_MUTED=true
        fi
        raw_vol="$(awk '{print $2}' <<< "$status_out" | head -n1)"
        VOLUME="$(awk -v v="${raw_vol:-0}" 'BEGIN { printf "%.0f", v * 100 }')"
    fi
elif command -v pactl >/dev/null 2>&1; then
    mute_out="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null || true)"
    if grep -qi "yes" <<< "$mute_out"; then
        IS_MUTED=true
    fi
    vol_out="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null || true)"
    VOLUME="$(grep -oP '\d+(?=%)' <<< "$vol_out" | head -n1 || echo "0")"
elif command -v pamixer >/dev/null 2>&1; then
    if [[ "$(pamixer --get-mute 2>/dev/null || echo "false")" == "true" ]]; then
        IS_MUTED=true
    fi
    VOLUME="$(pamixer --get-volume 2>/dev/null || echo "0")"
elif command -v amixer >/dev/null 2>&1; then
    amixer_out="$(amixer sget Master 2>/dev/null || true)"
    if grep -q "\[off\]" <<< "$amixer_out"; then
        IS_MUTED=true
    fi
    VOLUME="$(grep -oP '\d+(?=%)' <<< "$amixer_out" | head -n1 || echo "0")"
fi

# Ensure integer within 0-100
VOLUME="${VOLUME//[^0-9]/}"
VOLUME="${VOLUME:-0}"
if (( VOLUME > 100 )); then VOLUME=100; fi
if (( VOLUME < 0 )); then VOLUME=0; fi

# Determine icon and display text
if [[ "$IS_MUTED" == "true" ]]; then
    ICON="audio-volume-muted-symbolic"
    TITLE="Volume"
    SUBTEXT="Status: Muted"
    VOL_PARAM=""
else
    if (( VOLUME == 0 )); then
        ICON="audio-volume-muted-symbolic"
    elif (( VOLUME < 35 )); then
        ICON="audio-volume-low-symbolic"
    elif (( VOLUME < 70 )); then
        ICON="audio-volume-medium-symbolic"
    else
        ICON="audio-volume-high-symbolic"
    fi
    TITLE="Volume"
    SUBTEXT="Status: Active"
    VOL_PARAM="$VOLUME"
fi

if [[ -x "$NOTIFY_PROGRESS" ]]; then
    "$NOTIFY_PROGRESS" "$TITLE" "volume" "$VOL_PARAM" "$SUBTEXT" "$ICON" &
elif command -v notify-send >/dev/null 2>&1; then
    notify-send \
        -a "Volume" \
        -r 998 \
        -h "string:x-canonical-private-synchronous:volume" \
        -i "$ICON" \
        -t 1200 \
        "$TITLE" \
        "$SUBTEXT ${VOLUME}%" &
fi
