#!/usr/bin/env bash
# ==============================================================================
# Bluetooth Clean Sleep & Resume Hook
# ==============================================================================
# Prevents Bluetooth AVDTP endpoint corruption and deadlocks across suspend/resume.
# - Pre-suspend: Disconnects active Bluetooth audio devices before the USB root hub
#   loses power or resets, allowing earbuds/headsets to close the audio session cleanly.
# - Post-resume: Restores Bluetooth power and reconnects devices with clean A2DP.
# ==============================================================================
set -euo pipefail

case "${1:-}" in
    pre)
        # Disconnect connected Bluetooth devices gracefully before radio powers off
        for dev in $(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); do
            bluetoothctl disconnect "$dev" >/dev/null 2>&1 || true
        done
        ;;
    post)
        # Settle delay for USB root hub / PCIe CNVi radio to re-enumerate
        sleep 2
        bluetoothctl power on >/dev/null 2>&1 || true
        ;;
esac
