#!/usr/bin/env bash
# ==============================================================================
# Fix Intel AX211 Bluetooth SCO Packet Corruption & Audio Freeze
# ==============================================================================
# Root Cause:
# 1. Linux btusb driver defaults to enable_autosuspend=1, causing the Intel AX211
#    controller to enter USB sleep during audio streams.
# 2. Intel AX211 firmware reports incorrect SCO buffer sizes to Linux kernel,
#    triggering "Bluetooth: hci0: corrupted SCO packet" and "SCO packet for
#    unknown connection handle 257" during voice calls (HFP/SCO).
# 3. This corrupts the Bluetooth HCI state, causing "Protocol not available" and
#    freezing audio until Bluetooth is toggled off and on.
#
# Fix:
# - enable_autosuspend=0: Prevents controller sleep during audio/voice calls.
# - force_scofix=1: Forces kernel SCO buffer size alignment for Intel hardware.
# - reset=1: Sends clean HCI reset on initialization to clear hung controller states.
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo: sudo $0" >&2
    exit 1
fi

echo "Applying btusb kernel module configuration..."
cat << 'EOF' > /etc/modprobe.d/btusb.conf
# Fix Intel AX211 Bluetooth SCO buffer corruption and autosuspend dropouts
options btusb enable_autosuspend=0 force_scofix=1 reset=1
EOF

echo "Reloading btusb module and restarting bluetooth..."
# If btusb is in use, restart bluetooth.service first
systemctl stop bluetooth.service || true
modprobe -r btusb || true
modprobe btusb
systemctl start bluetooth.service

echo "Done! Intel AX211 btusb fix applied successfully."
