#!/bin/bash

set -e

SERVICE_DIR="./all"
DEST_DIR="/etc/systemd/system"
EXEC_DIR="./executables"
BIN_DEST="/usr/local/bin"

# Copy executables first
echo "Copying executables from $EXEC_DIR to $BIN_DEST..."
for exe_file in "$EXEC_DIR"/*; do
    exe_name=$(basename "$exe_file")
    echo "→ Installing $exe_name..."
    sudo cp "$exe_file" "$BIN_DEST"
    sudo chmod +x "$BIN_DEST/$exe_name"
done

echo ""
echo "Installing all .service files from $SERVICE_DIR..."
echo ""

# Loop over all .service files in the ./all directory
for service_file in "$SERVICE_DIR"/*.service; do
    service_name=$(basename "$service_file")
    service_dest="$DEST_DIR/$service_name"

    echo "→ Installing $service_name..."
    sudo cp "$service_file" "$service_dest"
    sudo chmod 644 "$service_dest"

    echo "→ Enabling and starting $service_name..."
    sudo systemctl enable --now "$service_name"
done

# Reload systemd in case any new units were added
echo ""
echo "Reloading systemd..."
sudo systemctl daemon-reexec

echo ""
echo "All executables from $EXEC_DIR have been copied to $BIN_DEST."
echo "All services from $SERVICE_DIR have been installed and started."
