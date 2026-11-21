#!/usr/bin/env bash
# ==============================================================================
# Microphone Volume & Mute Controller with OSD Feedback
# Supports PipeWire (wpctl), PulseAudio (pactl), pamixer, and ALSA (amixer)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_PROGRESS="$SCRIPT_DIR/notify-progress.sh"
if [[ ! -x "$NOTIFY_PROGRESS" && -x "$HOME/.config/hypr/scripts/notify-progress.sh" ]]; then
    NOTIFY_PROGRESS="$HOME/.config/hypr/scripts/notify-progress.sh"
fi

ACTION="${1:-toggle}"

adjust_mic() {
    local act="$1"
    if command -v wpctl >/dev/null 2>&1; then
        case "$act" in
            mute|toggle|toggle-mute|t)
                wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null || true
                ;;
            up|+5%|5%+|+)
                wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SOURCE@ 5%+ 2>/dev/null || true
                ;;
            down|-5%|5%-|-)
                wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%- 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SOURCE@ "$act" 2>/dev/null || true
                ;;
        esac
    elif command -v pactl >/dev/null 2>&1; then
        case "$act" in
            mute|toggle|toggle-mute|t)
                pactl set-source-mute @DEFAULT_SOURCE@ toggle 2>/dev/null || true
                ;;
            up|+5%|5%+|+)
                pactl set-source-volume @DEFAULT_SOURCE@ +5% 2>/dev/null || true
                ;;
            down|-5%|5%-|-)
                pactl set-source-volume @DEFAULT_SOURCE@ -5% 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                pactl set-source-volume @DEFAULT_SOURCE@ "$act" 2>/dev/null || true
                ;;
        esac
    elif command -v pamixer >/dev/null 2>&1; then
        case "$act" in
            mute|toggle|toggle-mute|t)
                pamixer --default-source -t 2>/dev/null || true
                ;;
            up|+5%|5%+|+)
                pamixer --default-source -i 5 2>/dev/null || true
                ;;
            down|-5%|5%-|-)
                pamixer --default-source -d 5 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                pamixer --default-source --set-volume "${act//[^0-9]/}" 2>/dev/null || true
                ;;
        esac
    elif command -v amixer >/dev/null 2>&1; then
        case "$act" in
            mute|toggle|toggle-mute|t)
                amixer -q sset Capture toggle 2>/dev/null || true
                ;;
            up|+5%|5%+|+)
                amixer -q sset Capture 5%+ 2>/dev/null || true
                ;;
            down|-5%|5%-|-)
                amixer -q sset Capture 5%- 2>/dev/null || true
                ;;
            status|get)
                ;;
            *)
                amixer -q sset Capture "$act" 2>/dev/null || true
                ;;
        esac
    fi
}

adjust_mic "$ACTION"

# Signal waybar custom/microphone module to update icon immediately
pkill -RTMIN+8 waybar 2>/dev/null || true

# Query current mic status
IS_MUTED=false
VOLUME=0

if command -v wpctl >/dev/null 2>&1; then
    status_out="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true)"
    if [[ -n "$status_out" ]]; then
        if grep -q "MUTED" <<< "$status_out"; then
            IS_MUTED=true
        fi
        raw_vol="$(awk '{print $2}' <<< "$status_out" | head -n1)"
        VOLUME="$(awk -v v="${raw_vol:-0}" 'BEGIN { printf "%.0f", v * 100 }')"
    fi
elif command -v pactl >/dev/null 2>&1; then
    mute_out="$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null || true)"
    if grep -qi "yes" <<< "$mute_out"; then
        IS_MUTED=true
    fi
    vol_out="$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null || true)"
    VOLUME="$(grep -oP '\d+(?=%)' <<< "$vol_out" | head -n1 || echo "0")"
elif command -v pamixer >/dev/null 2>&1; then
    if [[ "$(pamixer --default-source --get-mute 2>/dev/null || echo "false")" == "true" ]]; then
        IS_MUTED=true
    fi
    VOLUME="$(pamixer --default-source --get-volume 2>/dev/null || echo "0")"
elif command -v amixer >/dev/null 2>&1; then
    amixer_out="$(amixer sget Capture 2>/dev/null || true)"
    if grep -q "\[off\]" <<< "$amixer_out"; then
        IS_MUTED=true
    fi
    VOLUME="$(grep -oP '\d+(?=%)' <<< "$amixer_out" | head -n1 || echo "0")"
fi

VOLUME="${VOLUME//[^0-9]/}"
VOLUME="${VOLUME:-0}"
if (( VOLUME > 100 )); then VOLUME=100; fi
if (( VOLUME < 0 )); then VOLUME=0; fi

TITLE="Microphone"
if [[ "$IS_MUTED" == "true" ]]; then
    ICON="microphone-sensitivity-muted-symbolic"
    SUBTEXT="Status: Muted"
    VOL_PARAM=""
else
    ICON="microphone-sensitivity-high-symbolic"
    SUBTEXT="Status: Unmuted"
    VOL_PARAM="$VOLUME"
fi

if [[ -x "$NOTIFY_PROGRESS" ]]; then
    "$NOTIFY_PROGRESS" "$TITLE" "mic" "$VOL_PARAM" "$SUBTEXT" "$ICON" &
elif command -v notify-send >/dev/null 2>&1; then
    notify-send \
        -a "Microphone" \
        -r 997 \
        -h "string:x-canonical-private-synchronous:mic" \
        -i "$ICON" \
        -t 1200 \
        "$TITLE" \
        "$SUBTEXT ${VOLUME}%" &
fi
