#!/usr/bin/env bash
# ==============================================================================
# Disable USB Wake Setup (Hot Backpack Fix)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DEST="${1:-/usr/local/bin}"
SERVICE_DEST="${2:-/etc/systemd/system}"

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    echo "=== USB Sleep Wake Status Check ==="
    state=$(systemctl is-enabled disable-xhci-wake.service 2>/dev/null || echo "not-found")
    echo "disable-xhci-wake.service status: $state"
    if [[ -x /usr/local/bin/isolate-wake.sh ]]; then
        echo "isolate-wake.sh executable: installed"
    else
        echo "isolate-wake.sh executable: not found"
    fi
    exit 0
fi

# Clean up legacy USB wake udev rules and sleep hooks
sudo rm -f /etc/udev/rules.d/90-usb-wake-isolate.rules
sudo rm -f /usr/lib/systemd/system-sleep/isolate-wake.sh

# 1. Install executable
echo "Installing isolate-wake.sh to $BIN_DEST..."
sudo cp "$SCRIPT_DIR/isolate-wake.sh" "$BIN_DEST/isolate-wake.sh"
sudo chmod +x "$BIN_DEST/isolate-wake.sh"

# 2. Install systemd service
echo "Installing disable-xhci-wake.service to $SERVICE_DEST..."
sudo cp "$SCRIPT_DIR/disable-xhci-wake.service" "$SERVICE_DEST/disable-xhci-wake.service"
sudo chmod 644 "$SERVICE_DEST/disable-xhci-wake.service"

# 3. Reload systemd and enable/restart service
echo "Reloading systemd and enabling disable-xhci-wake.service..."
sudo systemctl daemon-reload
sudo systemctl enable --now disable-xhci-wake.service

# 4. Apply immediately
echo "Disabling USB wake triggers immediately..."
sudo "$BIN_DEST/isolate-wake.sh"
