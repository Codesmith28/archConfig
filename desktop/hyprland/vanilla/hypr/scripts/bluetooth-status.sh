#!/usr/bin/env bash
# ==============================================================================
# Bluetooth Status & Device Connection OSD Notification Helper
# Queries bluetoothctl for adapter state, connected devices, and battery level
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_PROGRESS="$SCRIPT_DIR/notify-progress.sh"
if [[ ! -x "$NOTIFY_PROGRESS" && -x "$HOME/.config/hypr/scripts/notify-progress.sh" ]]; then
    NOTIFY_PROGRESS="$HOME/.config/hypr/scripts/notify-progress.sh"
fi

ACTION="${1:-status}"

if [[ "$ACTION" == "toggle" ]]; then
    if command -v bluetoothctl >/dev/null 2>&1; then
        if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
            bluetoothctl power off 2>/dev/null || true
        else
            bluetoothctl power on 2>/dev/null || true
        fi
        sleep 0.5
    fi
fi

IS_POWERED=false
CONNECTED_DEVS=()
DEV_NAME=""
BATTERY=""

if command -v bluetoothctl >/dev/null 2>&1; then
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        IS_POWERED=true
        # Find connected devices
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                CONNECTED_DEVS+=("$line")
            fi
        done < <(bluetoothctl devices Connected 2>/dev/null || true)
    fi
fi

TITLE="Bluetooth"
if [[ "$IS_POWERED" == "false" ]]; then
    ICON="bluetooth-disabled-symbolic"
    SUBTEXT="Status: Powered Off"
    VOL_PARAM=""
elif [[ ${#CONNECTED_DEVS[@]} -eq 0 ]]; then
    ICON="bluetooth-active-symbolic"
    SUBTEXT="Status: Disconnected"
    VOL_PARAM=""
else
    # Parse first connected device
    first_dev="${CONNECTED_DEVS[0]}"
    mac="$(awk '{print $2}' <<< "$first_dev")"
    DEV_NAME="$(cut -d' ' -f3- <<< "$first_dev")"

    if [[ -n "$mac" ]]; then
        bat_raw="$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Battery Percentage" | head -n1 || true)"
        if [[ -n "$bat_raw" ]]; then
            BATTERY="$(grep -oP '\d+(?=%)' <<< "$bat_raw" || awk -F'[(%)]' '{print $2}' <<< "$bat_raw" || true)"
        fi
    fi

    ICON="bluetooth-active-symbolic"
    TITLE="Bluetooth: ${DEV_NAME:-Device}"
    if [[ -n "$BATTERY" ]]; then
        SUBTEXT="Battery: ${BATTERY}%\nStatus:  Connected"
        VOL_PARAM="${BATTERY//[^0-9]/}"
    else
        SUBTEXT="Status:  Connected (${#CONNECTED_DEVS[@]} active)"
        VOL_PARAM="100"
    fi
fi

if [[ -x "$NOTIFY_PROGRESS" ]]; then
    "$NOTIFY_PROGRESS" "$TITLE" "bluetooth" "$VOL_PARAM" "$SUBTEXT" "$ICON" &
elif command -v notify-send >/dev/null 2>&1; then
    notify-send \
        -a "Bluetooth" \
        -r 995 \
        -h "string:x-canonical-private-synchronous:bluetooth" \
        -i "$ICON" \
        -t 1500 \
        "$TITLE" \
        "$SUBTEXT" &
fi
