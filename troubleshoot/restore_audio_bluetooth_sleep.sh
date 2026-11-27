#!/usr/bin/env bash
# ==============================================================================
# Recover Bluetooth, PipeWire/WirePlumber Audio, and GNOME Media Keys
# ==============================================================================
# Resolves post-sleep or daemon-restart cascade failures where:
# 1. WirePlumber holds stale BlueZ transports/RFCOMM sockets after resume or
#    a standalone bluetooth.service restart.
# 2. PipeWire IPC stalls, causing gsd-media-keys to hang on volume feedback.
# 3. Super+Return and media shortcuts stop responding.
#
# Usage:
#   ./restore_audio_bluetooth_sleep.sh [--restart-bluetooth]
# ==============================================================================
set -euo pipefail

RESTART_BT=0
if [[ "${1:-}" == "--restart-bluetooth" || "${1:-}" == "-b" ]]; then
    RESTART_BT=1
fi

btctl() {
    if command -v timeout >/dev/null 2>&1; then
        timeout 3 bluetoothctl "$@"
    else
        bluetoothctl "$@"
    fi
}

if [[ $RESTART_BT -eq 1 ]]; then
    echo "==> [0/4] Restarting system bluetooth.service before audio stack..."
    sudo systemctl restart bluetooth.service
    sleep 1
fi

echo "==> [1/4] Restarting user audio services (PipeWire & WirePlumber)..."
systemctl --user restart pipewire pipewire-pulse wireplumber

echo "==> [2/4] Restarting GNOME shortcuts & media keys daemon (if running)..."
systemctl --user restart org.gnome.SettingsDaemon.MediaKeys.target 2>/dev/null || \
    gdbus call --session --dest org.gnome.SettingsDaemon.MediaKeys \
        --object-path /org/gnome/SettingsDaemon/MediaKeys \
        --method org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1 || true

echo "==> [3/4] Re-syncing connected Bluetooth audio devices..."
sleep 1
CONNECTED_DEVS=""
if command -v bluetoothctl >/dev/null 2>&1; then
    CONNECTED_DEVS="$(btctl devices Connected 2>/dev/null | awk '/^Device /{print $2}' || true)"
fi

if [[ -n "$CONNECTED_DEVS" ]]; then
    while IFS= read -r dev; do
        [[ -n "$dev" ]] || continue
        echo "    Re-negotiating audio profiles for $dev..."
        btctl disconnect "$dev" >/dev/null 2>&1 || true
        sleep 1
        btctl connect "$dev" >/dev/null 2>&1 || true
    done <<< "$CONNECTED_DEVS"
else
    echo "    No Bluetooth audio devices currently connected."
fi

echo "==> [4/4] Verifying audio sink and PipeWire responsiveness..."
sleep 2
if command -v wpctl >/dev/null 2>&1 && timeout 5s wpctl status >/dev/null 2>&1; then
    echo "==> SUCCESS: Audio subsystem and shortcuts restored!"
    echo "    Current sinks:"
    wpctl status | grep -A 5 "Sinks:" | head -n 6 || true
else
    echo "==> WARNING: wpctl status did not respond in 5s. Check: systemctl --user status wireplumber"
    exit 1
fi
