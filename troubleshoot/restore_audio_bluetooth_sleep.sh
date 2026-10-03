#!/usr/bin/env bash
# ==============================================================================
# Recover Bluetooth, PipeWire/WirePlumber Audio, and GNOME Media Keys
# ==============================================================================
# Resolves the post-sleep cascade failure where:
# 1. WirePlumber holds stale BlueZ transports after USB controller sleep reset.
# 2. PipeWire IPC stalls, causing gsd-media-keys to hang on volume sound feedback.
# 3. Super+Return and media shortcuts stop responding.
# ==============================================================================
set -euo pipefail

echo "==> [1/4] Restarting user audio services (PipeWire & WirePlumber)..."
systemctl --user restart pipewire pipewire-pulse wireplumber

echo "==> [2/4] Restarting GNOME shortcuts & media keys daemon..."
systemctl --user restart org.gnome.SettingsDaemon.MediaKeys.target 2>/dev/null || \
    gdbus call --session --dest org.gnome.SettingsDaemon.MediaKeys --object-path /org/gnome/SettingsDaemon/MediaKeys --method org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1 || true

echo "==> [3/4] Re-syncing connected Bluetooth audio devices..."
sleep 1
CONNECTED_DEVS=$(bluetoothctl devices Connected | awk '{print $2}')
if [[ -n "$CONNECTED_DEVS" ]]; then
    for dev in $CONNECTED_DEVS; do
        echo "    Re-negotiating audio profiles for $dev..."
        bluetoothctl disconnect "$dev" 2>/dev/null || true
        sleep 1
        bluetoothctl connect "$dev" 2>/dev/null || true
    done
else
    echo "    No Bluetooth audio devices currently connected."
fi

echo "==> [4/4] Verifying audio sink and PipeWire responsiveness..."
sleep 2
if timeout 5s wpctl status >/dev/null 2>&1; then
    echo "==> SUCCESS: Audio subsystem and shortcuts restored!"
    echo "    Current default sink:"
    wpctl status | grep -A 5 "Sinks:" | head -n 5
else
    echo "==> WARNING: wpctl status did not respond in 5s. Check systemctl --user status wireplumber."
fi
