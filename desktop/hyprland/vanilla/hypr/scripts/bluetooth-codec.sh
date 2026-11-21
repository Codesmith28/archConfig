#!/usr/bin/env bash
# ==============================================================================
# Interactive Bluetooth Audio Codec & Profile Selector for Waybar / Hyprland
# Switches between High-Res A2DP codecs (LDAC, AAC, SBC-XQ, SBC) and HSP/HFP
# ==============================================================================
set -euo pipefail

# 1. Ensure runtime environment
if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

notify_codec() {
    local title="$1"
    local msg="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Bluetooth Audio" -i "audio-headphones" "$title" "$msg" 2>/dev/null || true
    fi
}

# 2. Find active Bluetooth audio card
CARD_NAME=""
if command -v pactl >/dev/null 2>&1; then
    CARD_NAME="$(pactl list cards short 2>/dev/null | awk '/bluez_card/{print $2; exit}' || true)"
fi

if [[ -z "$CARD_NAME" ]]; then
    notify_codec "Bluetooth Audio" "No active Bluetooth audio device connected."
    exit 0
fi

# 3. Extract Card info, description, profiles, and active profile
CARD_INFO="$(pactl list cards 2>/dev/null | awk -v card="$CARD_NAME" '
    $0 ~ "Name: " card { found=1 }
    found && /^$/ { exit }
    found { print }
')"

DEVICE_DESC="$(echo "$CARD_INFO" | grep "device.description = " | head -n1 | cut -d'"' -f2 || true)"
if [[ -z "$DEVICE_DESC" ]]; then
    DEVICE_DESC="$(echo "$CARD_INFO" | grep "device.alias = " | head -n1 | cut -d'"' -f2 || echo "Bluetooth Headset")"
fi

ACTIVE_PROFILE="$(echo "$CARD_INFO" | grep "Active Profile:" | awk '{print $3}' || true)"

# 4. If called with --current, print current codec for Waybar module/tooltip
if [[ "${1:-}" == "--current" || "${1:-}" == "-c" ]]; then
    codec_name="SBC"
    case "$ACTIVE_PROFILE" in
        *ldac*) codec_name="LDAC" ;;
        *aac*) codec_name="AAC" ;;
        *sbc_xq*) codec_name="SBC-XQ" ;;
        *sbc*) codec_name="SBC" ;;
        *aptx_hd*) codec_name="aptX HD" ;;
        *aptx*) codec_name="aptX" ;;
        *msbc*) codec_name="mSBC (Headset)" ;;
        *cvsd*) codec_name="CVSD (Headset)" ;;
        *headset*) codec_name="HSP/HFP" ;;
        *) codec_name="$ACTIVE_PROFILE" ;;
    esac
    echo "$codec_name"
    exit 0
fi

# 5. Build list of available profiles with friendly labels and icons
PROFILES_RAW="$(echo "$CARD_INFO" | awk '/Profiles:/,/Active Profile:/' | grep -E '^[[:space:]]+[a-zA-Z0-9_-]+:' || true)"

MENU_LINES=()
declare -A PROFILE_MAP

while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    prof_id="$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')"
    prof_desc="$(echo "$line" | cut -d: -f2- | sed 's/ (sinks.*//' | sed 's/^[[:space:]]*//')"

    # Filter out off/null profiles from main view unless needed
    [[ "$prof_id" == "off" ]] && continue

    label=""
    case "$prof_id" in
        *ldac*)
            label="🎧 LDAC (Hi-Res Audio 990kbps)"
            ;;
        *aac*)
            label="🎵 AAC (High Quality 320kbps)"
            ;;
        *sbc_xq*)
            label="📻 SBC-XQ (Enhanced SBC High Bitrate)"
            ;;
        *sbc*)
            label="🔉 SBC (Standard Bluetooth Audio)"
            ;;
        *aptx_hd*)
            label="🎧 aptX HD (High Definition Audio)"
            ;;
        *aptx*)
            label="🎵 aptX (Low Latency Audio)"
            ;;
        *msbc*)
            label="🎙️ mSBC (Wideband Voice / Microphone)"
            ;;
        *cvsd*)
            label="📞 CVSD (Standard Voice / Microphone)"
            ;;
        *headset-head-unit*)
            label="🎙️ Headset Unit (Mic + Low Latency Mono)"
            ;;
        *a2dp-sink*)
            label="🎧 High Fidelity Playback (A2DP)"
            ;;
        *)
            label="󰂱 $prof_desc ($prof_id)"
            ;;
    esac

    if [[ "$prof_id" == "$ACTIVE_PROFILE" ]]; then
        menu_entry="●  $label  [ACTIVE]"
    else
        menu_entry="○  $label"
    fi

    MENU_LINES+=("$menu_entry")
    PROFILE_MAP["$menu_entry"]="$prof_id"
done <<< "$PROFILES_RAW"

if [[ ${#MENU_LINES[@]} -eq 0 ]]; then
    notify_codec "$DEVICE_DESC" "No alternate audio codecs available for this device."
    exit 0
fi

# 6. Show launcher menu (wofi or rofi)
CHOSEN=""
MENU_TEXT="$(printf "%s\n" "${MENU_LINES[@]}")"

if command -v wofi >/dev/null 2>&1; then
    CHOSEN="$(echo -e "$MENU_TEXT" | wofi \
        --dmenu \
        --prompt "Codec for $DEVICE_DESC" \
        --width 480 \
        --lines $((${#MENU_LINES[@]} + 1)) \
        --location center \
        --allow-images false \
        --insensitive 2>/dev/null || true)"
elif command -v rofi >/dev/null 2>&1; then
    CHOSEN="$(echo -e "$MENU_TEXT" | rofi \
        -dmenu \
        -p "Bluetooth Codec" \
        -theme-str 'window {width: 480px;}' 2>/dev/null || true)"
fi

if [[ -z "$CHOSEN" ]]; then
    exit 0
fi

TARGET_PROF="${PROFILE_MAP["$CHOSEN"]:-}"
if [[ -n "$TARGET_PROF" && "$TARGET_PROF" != "$ACTIVE_PROFILE" ]]; then
    pactl set-card-profile "$CARD_NAME" "$TARGET_PROF" 2>/dev/null || true
    # Brief delay for pipewire to update card profile
    sleep 0.3
    notify_codec "$DEVICE_DESC" "Switched codec to: $(echo "$CHOSEN" | sed 's/^[●○][[:space:]]*//' | sed 's/  \[ACTIVE\]//')"
    # Refresh Waybar modules
    pkill -RTMIN+8 waybar 2>/dev/null || true
fi

exit 0
