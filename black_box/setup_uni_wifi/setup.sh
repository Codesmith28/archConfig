#!/bin/bash

cat << "EOF"
             _            _  __ _
 _   _ _ __ (_) __      _(_)/ _(_)
| | | | '_ \| | \ \ /\ / / | |_| |
| |_| | | | | |  \ V  V /| |  _| |
 \__,_|_| |_|_|___\_/\_/ |_|_| |_|
             |_____|
EOF

NETWORK_MANAGER_ETC_DIR=/etc/NetworkManager/conf.d/
CONFIGURATION_DIR=./configurations/
TEMP_CONFIG_FILE="$CONFIGURATION_DIR/temp.8021x"

# move the configuration file to the NetworkManager directory
cp "$CONFIGURATION_DIR"/* $NETWORK_MANAGER_ETC_DIR

echo "Create a new wifi entry using nm-connection editor..."
read -p "Enter the name of the wifi network: " WIFI_NAME
nm-connection-editor
read -p "Press [Enter] key to continue after creating an entry..."

# Prompt for university credentials
read -p "Enter your university identity: " IDENTITY
read -p "Enter your university password: " PASSWORD

# Create a new configuration file with the user's credentials
NEW_CONFIG_FILE="$CONFIGURATION_DIR/${WIFI_NAME}.8021x"
cp "$TEMP_CONFIG_FILE" "$NEW_CONFIG_FILE"

# Use sed to replace placeholders with actual credentials
sed -i "s/EAP-Identity=/EAP-Identity=$IDENTITY/" "$NEW_CONFIG_FILE"
sed -i "s/EAP-PEAP-Phase2-Identity=/EAP-PEAP-Phase2-Identity=$IDENTITY/" "$NEW_CONFIG_FILE"
sed -i "s/EAP-PEAP-Phase2-Password=/EAP-PEAP-Phase2-Password=$PASSWORD/" "$NEW_CONFIG_FILE"

echo "Setting up the wifi connection..."

# Copy the new configuration to NetworkManager directory
cp "$NEW_CONFIG_FILE" $NETWORK_MANAGER_ETC_DIR
rm "$NEW_CONFIG_FILE"
