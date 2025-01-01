#!/bin/bash

cat << "EOF"
 _ __ ___ _ __ ___   __ _ _ __
| '__/ _ \ '_ ` _ \ / _` | '_ \
| | |  __/ | | | | | (_| | |_) |
|_|  \___|_| |_| |_|\__,_| .__/
                         |_|
EOF

pacman -S keyd

systemctl enable keyd
systemctl start keyd

CONFIGURATION_FILE="./configurations/default.conf"

if [ -f "$CONFIGURATION_FILE" ]; then
    echo "Configuration file found. Copying to /etc/keyd.conf"
    cp $CONFIGURATION_FILE /etc/keyd/
else
    echo "Configuration file not found. Using default configuration."
fi

systemctl restart keyd
