#!/bin/bash

cat << "EOF"
  __             _                           __
 / _| ___  _ __ | |_ ___     ___ ___  _ __  / _|
| |_ / _ \| '_ \| __/ __|   / __/ _ \| '_ \| |_
|  _| (_) | | | | |_\__ \  | (_| (_) | | | |  _|
|_|  \___/|_| |_|\__|___/___\___\___/|_| |_|_|
                       |_____|
EOF

if [ $EUID -ne 0 ]; then
    echo "This should run as sudo"
    exit 1
fi

# remove all the monospace fonts under /usr/share/fonts/noto && /usr/share/fonts/liberation/
rm -rf /usr/share/fonts/noto/*Mono*
rm -rf /usr/share/fonts/liberation/*Mono*
