#!/bin/bash

cat << "EOF"
             _            _  __ _
 _   _ _ __ (_) __      _(_)/ _(_)
| | | | '_ \| | \ \ /\ / / | |_| |
| |_| | | | | |  \ V  V /| |  _| |
 \__,_|_| |_|_|___\_/\_/ |_|_| |_|
             |_____|
EOF

# Resolve absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_MANAGER_ETC_DIR="/etc/NetworkManager/conf.d/"
CONFIGURATION_DIR="$SCRIPT_DIR/configurations"
TEMP_CONFIG_FILE="$CONFIGURATION_DIR/temp.8021x"

# Ensure configuration directory exists
if [[ ! -d "$CONFIGURATION_DIR" ]]; then
    echo "Error: Configuration directory $CONFIGURATION_DIR does not exist!"
    exit 1
fi

# Move all configuration files to NetworkManager directory
echo "Copying configuration files to $NETWORK_MANAGER_ETC_DIR..."
sudo cp "$CONFIGURATION_DIR"/* "$NETWORK_MANAGER_ETC_DIR"

echo "Create a new WiFi entry using nm-connection-editor..."
read -p "Enter the name of the WiFi network: " WIFI_NAME
nm-connection-editor
read -p "Press [Enter] key to continue after creating an entry..."

# Prompt for university credentials
read -p "Enter your university identity: " IDENTITY
read -sp "Enter your university password: " PASSWORD
echo ""

# Ensure temp config file exists
if [[ ! -f "$TEMP_CONFIG_FILE" ]]; then
    echo "Error: Template configuration file $TEMP_CONFIG_FILE not found!"
    exit 1
fi

# Create a new configuration file with the user's credentials
NEW_CONFIG_FILE="$CONFIGURATION_DIR/${WIFI_NAME}.8021x"
cp "$TEMP_CONFIG_FILE" "$NEW_CONFIG_FILE"

# Replace placeholders with actual credentials
sed -i "s/EAP-Identity=/EAP-Identity=$IDENTITY/" "$NEW_CONFIG_FILE"
sed -i "s/EAP-PEAP-Phase2-Identity=/EAP-PEAP-Phase2-Identity=$IDENTITY/" "$NEW_CONFIG_FILE"
sed -i "s/EAP-PEAP-Phase2-Password=/EAP-PEAP-Phase2-Password=$PASSWORD/" "$NEW_CONFIG_FILE"

echo "Setting up the WiFi connection..."

# Copy the new configuration to NetworkManager directory
sudo cp "$NEW_CONFIG_FILE" "$NETWORK_MANAGER_ETC_DIR"
rm "$NEW_CONFIG_FILE"

echo "WiFi setup completed!"
