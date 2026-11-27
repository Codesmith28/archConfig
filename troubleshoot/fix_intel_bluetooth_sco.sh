#!/usr/bin/env bash
# ==============================================================================
# Fix Intel AX211 Bluetooth USB Autosuspend & Cleanly Re-Sync BlueZ/WirePlumber
# ==============================================================================
# Root Cause:
# 1. Linux btusb defaults to enable_autosuspend=1, allowing USB runtime-PM sleep
#    during audio/voice transitions on Intel CNVi / AX211 (8087:0033).
# 2. Setting force_scofix=1 activates BTUSB_WRONG_SCO_MTU (a legacy Broadcom/CSR
#    quirk that forces sco_mtu=64), which overrides the Intel AX211 controller's
#    real SCO MTU and causes/worsens "corrupted SCO packet" and
#    "SCO packet for unknown connection handle" errors during HFP/mSBC calls.
# 3. Restarting bluetooth.service without restarting user PipeWire/WirePlumber
#    triggers "rfcomm_bind: Address already in use (98)" and WirePlumber deadlocks.
#
# Fix:
# - Writes "options btusb enable_autosuspend=0" (without force_scofix=1 / reset=1).
# - Reloads btusb, restarts bluetooth.service, and restarts the invoking user's
#   PipeWire/WirePlumber session services in lockstep.
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo: sudo $0" >&2
    exit 1
fi

echo "Applying btusb kernel module configuration..."
cat << 'EOF' > /etc/modprobe.d/btusb.conf
# Intel AX211 / USB Bluetooth Configuration
# Disable autosuspend without forcing legacy BTUSB_WRONG_SCO_MTU (force_scofix=1)
options btusb enable_autosuspend=0
EOF
chmod 644 /etc/modprobe.d/btusb.conf

echo "Reloading btusb module and restarting bluetooth..."
systemctl stop bluetooth.service || true
if ! modprobe -r btusb || ! modprobe btusb; then
    echo "Warning: Could not reload btusb live; reboot to apply btusb.conf." >&2
fi
systemctl start bluetooth.service

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    target_uid="$(id -u "$SUDO_USER" 2>/dev/null || true)"
    if [[ -n "$target_uid" && -S "/run/user/$target_uid/bus" ]]; then
        echo "Restarting user audio stack ($SUDO_USER) to re-sync with BlueZ..."
        sudo -u "$SUDO_USER" env \
            XDG_RUNTIME_DIR="/run/user/$target_uid" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$target_uid/bus" \
            systemctl --user restart wireplumber pipewire pipewire-pulse || true
    fi
else
    echo "Note: Run 'systemctl --user restart wireplumber pipewire pipewire-pulse' as your user."
fi

echo "Done! Intel AX211 btusb fix applied."
