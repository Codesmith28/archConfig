#!/usr/bin/env bash
# ==============================================================================
# Battery Charging Limit & Deep Sleep Setup (85% Cap + S3 Suspend)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DEST="${1:-/usr/local/bin}"
SERVICE_DEST="${2:-/etc/systemd/system}"

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
