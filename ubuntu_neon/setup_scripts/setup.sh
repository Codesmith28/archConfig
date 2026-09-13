#!/bin/bash

set -e

SERVICE_DIR="./all"
DEST_DIR="/etc/systemd/system"
EXEC_DIR="./executables"
BIN_DEST="/usr/local/bin"

echo "Cleaning up legacy/deprecated services..."
# Stop and remove the old broken XHCI service if it exists on the system
if systemctl is-active --quiet disable-xhci-wake.service || systemctl is-enabled --quiet disable-xhci-wake.service 2>/dev/null; then
    echo "→ Removing disable-xhci-wake.service from system..."
    sudo systemctl disable --now disable-xhci-wake.service || true
    sudo rm -f "$DEST_DIR/disable-xhci-wake.service"
    sudo rm -f "$BIN_DEST/disable-usb-wake.sh"
fi

echo ""
echo "Copying executables from $EXEC_DIR to $BIN_DEST..."
for exe_file in "$EXEC_DIR"/*; do
    exe_name=$(basename "$exe_file")

    # Skip the deprecated script if it is still in the local directory
    if [ "$exe_name" == "disable-usb-wake.sh" ]; then
        continue
    fi

    echo "→ Installing $exe_name..."
    sudo cp "$exe_file" "$BIN_DEST"
    sudo chmod +x "$BIN_DEST/$exe_name"
done

echo ""
echo "Installing all .service files from $SERVICE_DIR..."
echo ""

for service_file in "$SERVICE_DIR"/*.service; do
    service_name=$(basename "$service_file")

    # Skip the deprecated service if it is still in the local directory
    if [ "$service_name" == "disable-xhci-wake.service" ]; then
        continue
    fi

    service_dest="$DEST_DIR/$service_name"

    echo "→ Installing $service_name..."
    sudo cp "$service_file" "$service_dest"
    sudo chmod 644 "$service_dest"

    echo "→ Enabling and starting $service_name..."
    sudo systemctl enable --now "$service_name"
done

echo ""
echo "Configuring kernel for Deep Sleep (S3)..."
echo "→ Injecting mem_sleep_default=deep into GRUB..."
sudo grubby --update-kernel=ALL --args="mem_sleep_default=deep"

echo ""
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo ""
echo "Deployment Complete."
echo "Executables mapped to $BIN_DEST."
echo "Active services installed and started."
echo "Kernel updated. Please reboot for the deep sleep configuration to take effect."
