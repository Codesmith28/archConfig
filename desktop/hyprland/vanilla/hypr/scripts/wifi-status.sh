#!/usr/bin/env bash
# ==============================================================================
# Wi-Fi Status & Signal Strength OSD Notification Helper
# Queries NetworkManager (nmcli) / iwctl and displays connection details with
# monospace signal strength progress bar.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_PROGRESS="$SCRIPT_DIR/notify-progress.sh"
if [[ ! -x "$NOTIFY_PROGRESS" && -x "$HOME/.config/hypr/scripts/notify-progress.sh" ]]; then
    NOTIFY_PROGRESS="$HOME/.config/hypr/scripts/notify-progress.sh"
fi

ACTION="${1:-status}"

# Optional toggle action
if [[ "$ACTION" == "toggle" ]]; then
    if command -v nmcli >/dev/null 2>&1; then
        state="$(nmcli radio wifi 2>/dev/null || true)"
        if [[ "$state" == "enabled" ]]; then
            nmcli radio wifi off 2>/dev/null || true
        else
            nmcli radio wifi on 2>/dev/null || true
        fi
        sleep 0.5
    fi
fi

SSID=""
SIGNAL=0
IS_CONNECTED=false
IS_ENABLED=true

if command -v nmcli >/dev/null 2>&1; then
    radio="$(nmcli radio wifi 2>/dev/null || echo "enabled")"
    if [[ "$radio" == "disabled" ]]; then
        IS_ENABLED=false
    else
        # Find active connection
        active_line="$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -n1 || true)"
        if [[ -z "$active_line" ]]; then
            active_line="$(nmcli -t -f in-use,ssid,signal dev wifi 2>/dev/null | grep '^\*' | head -n1 || true)"
        fi
        if [[ -n "$active_line" ]]; then
            IS_CONNECTED=true
            SSID="$(cut -d: -f2 <<< "$active_line")"
            SIGNAL="$(cut -d: -f3 <<< "$active_line" || echo "0")"
        fi
    fi
elif command -v iwctl >/dev/null 2>&1; then
    # iwctl fallback
    station_out="$(iwctl station list 2>/dev/null | grep 'connected' | head -n1 || true)"
    if [[ -n "$station_out" ]]; then
        IS_CONNECTED=true
        SSID="$(awk '{print $3}' <<< "$station_out")"
        SIGNAL=70
    fi
fi

SIGNAL="${SIGNAL//[^0-9]/}"
SIGNAL="${SIGNAL:-0}"
if (( SIGNAL > 100 )); then SIGNAL=100; fi
if (( SIGNAL < 0 )); then SIGNAL=0; fi

TITLE="Wi-Fi"
if [[ "$IS_ENABLED" == "false" ]]; then
    ICON="network-wireless-disabled-symbolic"
    SUBTEXT="Status: Wi-Fi Disabled"
    VOL_PARAM=""
elif [[ "$IS_CONNECTED" == "true" ]]; then
    if (( SIGNAL >= 80 )); then
        ICON="network-wireless-signal-excellent-symbolic"
    elif (( SIGNAL >= 60 )); then
        ICON="network-wireless-signal-good-symbolic"
    elif (( SIGNAL >= 40 )); then
        ICON="network-wireless-signal-ok-symbolic"
    elif (( SIGNAL >= 20 )); then
        ICON="network-wireless-signal-weak-symbolic"
    else
        ICON="network-wireless-signal-none-symbolic"
    fi
    TITLE="Wi-Fi: ${SSID:-Connected}"
    SUBTEXT="Signal: ${SIGNAL}%"
    VOL_PARAM="$SIGNAL"
else
    ICON="network-wireless-offline-symbolic"
    SUBTEXT="Status: Disconnected"
    VOL_PARAM=""
fi

if [[ -x "$NOTIFY_PROGRESS" ]]; then
    "$NOTIFY_PROGRESS" "$TITLE" "wifi" "$VOL_PARAM" "$SUBTEXT" "$ICON" &
elif command -v notify-send >/dev/null 2>&1; then
    notify-send \
        -a "Network" \
        -r 996 \
        -h "string:x-canonical-private-synchronous:wifi" \
        -i "$ICON" \
        -t 1500 \
        "$TITLE" \
        "$SUBTEXT" &
fi
