#!/bin/bash

cat <<"EOF"
     _             _
 ___| |_ __ _ _ __| |_ _   _ _ __
/ __| __/ _` | '__| __| | | | '_ \
\__ \ || (_| | |  | |_| |_| | |_) |
|___/\__\__,_|_|   \__|\__,_| .__/
                             |_|
EOF

echo "Setting up startup applications for Arch Linux..."

STARTUP_DIR="$HOME/dotfiles/systemd/user"

# Ensure the startup directory exists
if [ ! -d "$STARTUP_DIR" ]; then
    echo "Error: $STARTUP_DIR does not exist."
    exit 1
fi

setup_service() {
    local service_name="$1"
    local service_file="${service_name}.service"
    local service_path="$STARTUP_DIR/$service_file"

    echo "Setting up ${service_name} startup script..."

    if [ -f "$service_path" ]; then
        echo "${service_file} found in $STARTUP_DIR."

        echo "Enabling ${service_file}..."
        systemctl --user enable "$service_file"

        echo "Starting ${service_file}..."
        systemctl --user start "$service_file"

        echo "${service_name^} startup script set!"
    else
        echo "Error: ${service_file} not found in $STARTUP_DIR."
    fi
}

# Loop through service files in the startup directory
for service_path in "$STARTUP_DIR"/*.service; do
    if [ -f "$service_path" ]; then
        service_name=$(basename "$service_path" .service)
        setup_service "$service_name"
    fi
done

# Enable system-level Bluetooth service
echo "Enabling Bluetooth service..."
sudo systemctl enable --now bluetooth.service

echo "Script execution completed."
