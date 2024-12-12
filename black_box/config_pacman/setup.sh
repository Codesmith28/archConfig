#!/bin/bash

cat << "EOF"
 _ __   __ _  ___ _ __ ___   __ _ _ __      ___ ___  _ __  / _|
| '_ \ / _` |/ __| '_ ` _ \ / _` | '_ \    / __/ _ \| '_ \| |_
| |_) | (_| | (__| | | | | | (_| | | | |  | (_| (_) | | | |  _|
| .__/ \__,_|\___|_| |_| |_|\__,_|_| |_|___\___\___/|_| |_|_|
|_|                                   |_____|
EOF

if [ $EUID -ne 0 ]; then
    echo "This should run as sudo"
    exit 1
fi

cp ./pacman.conf /etc/
echo "Pacman setup complete"
