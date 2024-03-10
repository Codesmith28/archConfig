#!/bin/bash
#  _____ _                     _     _  __ _   
# |_   _(_)_ __ ___   ___  ___| |__ (_)/ _| |_ 
#   | | | | '_ ` _ \ / _ \/ __| '_ \| | |_| __|
#   | | | | | | | | |  __/\__ \ | | | |  _| |_ 
#   |_| |_|_| |_| |_|\___||___/_| |_|_|_|  \__|
#                                              

sleep 1
clear
figlet "Timeshift"

_isInstalledYay() {
    package="$1";
    check="$(yay -Qs --color always "${package}" | grep "local" | grep "${package} ")";
    if [ -n "${check}" ] ; then
        echo 0; #'0' means 'true' in Bash
        return; #true
    fi;
    echo 1; #'1' means 'false' in Bash
    return; #false
}

timeshift_installed=$(_isInstalledYay "timeshift")
grubbtrfs_installed=$(_isInstalledYay "grub-btrfs")

if [[ $timeshift_installed == "0" ]] ;then
    echo ":: Timeshift is already installed"
else
    if gum confirm "DO YOU WANT TO INSTALL Timeshift now?" ;then
        yay -S timeshift
    fi
fi
if [[ -d /boot/grub ]] && [[ $grubbtrfs_installed == "0" ]] ;then
    echo ":: grub-btrfs is already installed"
else
    echo ":: grub-btrfs is required to select a snapshot on grub bootloader."
    if gum confirm "DO YOU WANT TO INSTALL grub-btrfs now?" ;then
        yay -S grub-btrfs
    fi
fi
sleep 3
