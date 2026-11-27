#!/usr/bin/env bash
# ==============================================================================
# Bluetooth Clean Sleep & Resume Hook
# ==============================================================================
# Prevents Bluetooth AVDTP endpoint corruption and deadlocks across suspend/resume.
# - Pre-suspend: Records connected devices, gracefully disconnects them so
#   headset firmware closes AVDTP/HFP sessions cleanly before xHCI/CNVi suspends.
# - Post-resume: Waits for hci0 and bluetoothd readiness, ensures controller power
#   is on, and reconnects previously connected devices cleanly.
# ==============================================================================
set -euo pipefail

STATE_FILE="/run/bluetooth-sleep-connected"

btctl() {
    if command -v timeout >/dev/null 2>&1; then
        timeout 3 bluetoothctl "$@"
    else
        bluetoothctl "$@"
    fi
}

command -v bluetoothctl >/dev/null 2>&1 || exit 0
if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active --quiet bluetooth.service 2>/dev/null || exit 0
fi

case "${1:-}" in
    pre)
        rm -f "$STATE_FILE"
        connected_devs="$(btctl devices Connected 2>/dev/null | awk '/^Device /{print $2}' || true)"
        if [[ -n "$connected_devs" ]]; then
            printf '%s\n' "$connected_devs" > "$STATE_FILE"
            chmod 600 "$STATE_FILE" 2>/dev/null || true
            while IFS= read -r dev; do
                [[ -n "$dev" ]] || continue
                btctl disconnect "$dev" >/dev/null 2>&1 || true
            done <<< "$connected_devs"
            # Allow L2CAP/AVDTP disconnect frames to transmit before tasks freeze
            sleep 0.5
        fi
        ;;
    post)
        # Wait up to 5s for the USB/CNVi HCI adapter and bluetoothd to become ready
        for _ in $(seq 1 10); do
            if [[ -d /sys/class/bluetooth/hci0 ]] && btctl show >/dev/null 2>&1; then
                break
            fi
            sleep 0.5
        done

        btctl power on >/dev/null 2>&1 || true

        if [[ -f "$STATE_FILE" ]]; then
            # Let BlueZ/WirePlumber endpoints settle after seat resume before reconnecting
            sleep 2
            while IFS= read -r dev; do
                [[ -n "$dev" ]] || continue
                if ! btctl info "$dev" 2>/dev/null | grep -q "Connected: yes"; then
                    btctl connect "$dev" >/dev/null 2>&1 || true
                fi
            done < "$STATE_FILE"
            rm -f "$STATE_FILE"
        fi
        ;;
esac
