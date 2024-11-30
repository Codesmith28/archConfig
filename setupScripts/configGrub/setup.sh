#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# move the ./grub file to /etc/default/
cp ./grub /etc/default/
