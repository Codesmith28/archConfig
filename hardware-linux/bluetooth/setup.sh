#!/usr/bin/env bash
# ==============================================================================
# Bluetooth Clean Sleep Hook Setup
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DEST="${1:-/usr/lib/systemd/system-sleep}"

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    echo "=== Bluetooth Hardware & Sleep Status Check ==="
    if [[ -f /etc/modprobe.d/btusb.conf ]]; then
        echo "btusb.conf: installed (/etc/modprobe.d/btusb.conf)"
        grep -q "force_scofix=1" /etc/modprobe.d/btusb.conf && echo "  • Intel SCO buffer alignment (force_scofix=1): active"
        grep -q "enable_autosuspend=0" /etc/modprobe.d/btusb.conf && echo "  • Audio stream autosuspend block (enable_autosuspend=0): active"
    else
        echo "btusb.conf: NOT found in /etc/modprobe.d/"
    fi
    if [[ -x /usr/lib/systemd/system-sleep/bluetooth-sleep.sh ]]; then
        echo "bluetooth-sleep.sh hook: installed and executable"
    else
        echo "bluetooth-sleep.sh hook: not found in /usr/lib/systemd/system-sleep"
    fi
    if [[ -f /etc/bluetooth/main.conf ]]; then
        echo "main.conf: /etc/bluetooth/main.conf present"
        grep -qi "^[[:space:]]*FastConnectable[[:space:]]*=[[:space:]]*true" /etc/bluetooth/main.conf && echo "  • FastConnectable: active" || echo "  • FastConnectable: not enabled"
        grep -qi "^[[:space:]]*Experimental[[:space:]]*=[[:space:]]*true" /etc/bluetooth/main.conf && echo "  • Battery reporting & LE Audio (Experimental): active" || echo "  • Battery reporting (Experimental): not enabled"
        grep -qi "^[[:space:]]*AutoEnable[[:space:]]*=[[:space:]]*true" /etc/bluetooth/main.conf && echo "  • Controller AutoEnable: active" || echo "  • Controller AutoEnable: not enabled"
    fi
    exit 0
fi

# 1. Install btusb modprobe configuration (Intel AX211 SCO packet fix)
if [[ -f "$SCRIPT_DIR/btusb.conf" ]]; then
    echo "Installing btusb kernel configuration..."
    sudo cp "$SCRIPT_DIR/btusb.conf" /etc/modprobe.d/btusb.conf
    sudo chmod 644 /etc/modprobe.d/btusb.conf
    echo "Installed /etc/modprobe.d/btusb.conf"
fi

# 2. Configure BlueZ main.conf (FastConnectable, Battery reporting, AutoEnable)
if [[ -f "$SCRIPT_DIR/main.conf" && -f /etc/bluetooth/main.conf ]]; then
    echo "Configuring BlueZ main.conf optimizations..."
    sudo sed -i 's|^#*[[:space:]]*FastConnectable[[:space:]]*=.*|FastConnectable = true|' /etc/bluetooth/main.conf
    sudo sed -i 's|^#*[[:space:]]*JustWorksRepairing[[:space:]]*=.*|JustWorksRepairing = always|' /etc/bluetooth/main.conf
    sudo sed -i 's|^#*[[:space:]]*Experimental[[:space:]]*=.*|Experimental = true|' /etc/bluetooth/main.conf
    sudo sed -i 's|^#*[[:space:]]*MultiProfile[[:space:]]*=.*|MultiProfile = multiple|' /etc/bluetooth/main.conf
    sudo sed -i 's|^#*[[:space:]]*AutoEnable[[:space:]]*=.*|AutoEnable = true|' /etc/bluetooth/main.conf
    sudo sed -i 's|^#*[[:space:]]*ReconnectAttempts[[:space:]]*=.*|ReconnectAttempts = 7|' /etc/bluetooth/main.conf
    sudo sed -i 's|^#*[[:space:]]*ReconnectIntervals[[:space:]]*=.*|ReconnectIntervals = 1, 2, 4, 8, 16, 32, 64|' /etc/bluetooth/main.conf
    echo "Optimized /etc/bluetooth/main.conf (FastConnectable, Battery reporting, AutoEnable, Auto-Reconnect)"
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl try-restart bluetooth.service 2>/dev/null || true
    fi
fi

# 3. Install bluetooth sleep hook
echo "Installing bluetooth-sleep hook to $HOOK_DEST..."
sudo mkdir -p "$HOOK_DEST"
sudo cp "$SCRIPT_DIR/bluetooth-sleep.sh" "$HOOK_DEST/bluetooth-sleep.sh"
sudo chmod +x "$HOOK_DEST/bluetooth-sleep.sh"

echo "Bluetooth hardware configuration and sleep hook installed successfully."
