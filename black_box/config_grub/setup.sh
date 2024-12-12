#!/bin/bash

cat << "EOF"
                  _                 _
  __ _ _ __ _   _| |__     ___  ___| |_ _   _ _ __
 / _` | '__| | | | '_ \   / __|/ _ \ __| | | | '_ \
| (_| | |  | |_| | |_) |  \__ \  __/ |_| |_| | |_) |
 \__, |_|   \__,_|_.__/___|___/\___|\__|\__,_| .__/
 |___/               |_____|                 |_|
EOF

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

pacman -S os-prober
cp ./grub /etc/default/
grub-mkconfig -o /boot/grub/grub.cfg

echo "Grub setup complete"
