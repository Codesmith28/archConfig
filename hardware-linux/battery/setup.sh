#!/usr/bin/env bash
# ==============================================================================
# Battery Charging Limit & Deep Sleep Setup (85% Cap + S3 Suspend)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DEST="${1:-/usr/local/bin}"
SERVICE_DEST="${2:-/etc/systemd/system}"

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    echo "=== Battery Threshold Status Check ==="
    for psy in /sys/class/power_supply/*; do
        if [ -f "$psy/type" ] && [ "$(cat "$psy/type" 2>/dev/null)" = "Battery" ]; then
            echo "Device: $(basename "$psy")"
            for node in charge_control_end_threshold charge_stop_threshold; do
                if [ -f "$psy/$node" ]; then
                    echo "  $node: $(cat "$psy/$node" 2>/dev/null)%"
                fi
            done
        fi
    done
    state=$(systemctl is-enabled battery-limit.service 2>/dev/null || echo "not-found")
    echo "battery-limit.service status: $state"
    exit 0
fi

# Clean up legacy / over-engineered files if present
sudo rm -f /etc/udev/rules.d/90-battery-limit.rules
sudo rm -f /usr/lib/systemd/system-sleep/set-battery-limit.sh
sudo rm -f /etc/tmpfiles.d/deep-sleep.conf
sudo rm -f /etc/systemd/sleep.conf.d/deep-sleep.conf

# 1. Install executable
echo "Installing set-battery-limit.sh to $BIN_DEST..."
sudo cp "$SCRIPT_DIR/set-battery-limit.sh" "$BIN_DEST/set-battery-limit.sh"
sudo chmod +x "$BIN_DEST/set-battery-limit.sh"

# 2. Install systemd service
echo "Installing battery-limit.service to $SERVICE_DEST..."
sudo cp "$SCRIPT_DIR/battery-limit.service" "$SERVICE_DEST/battery-limit.service"
sudo chmod 644 "$SERVICE_DEST/battery-limit.service"

echo "Reloading systemd and enabling battery-limit.service..."
sudo systemctl daemon-reload
sudo systemctl enable --now battery-limit.service

# 3. Configure Deep Sleep (S3) iff GRUB is available
if command -v grubby >/dev/null 2>&1 && { [ -d /boot/grub ] || [ -d /boot/grub2 ] || command -v grub-mkconfig >/dev/null 2>&1 || command -v grub2-mkconfig >/dev/null 2>&1; }; then
    echo "Configuring kernel for Deep Sleep (S3)..."
    echo "→ Injecting mem_sleep_default=deep into GRUB..."
    sudo grubby --update-kernel=ALL --args="mem_sleep_default=deep"
fi
