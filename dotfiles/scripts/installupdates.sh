#!/bin/bash
#  ___           _        _ _   _   _           _       _             
# |_ _|_ __  ___| |_ __ _| | | | | | |_ __   __| | __ _| |_ ___  ___  
#  | || '_ \/ __| __/ _` | | | | | | | '_ \ / _` |/ _` | __/ _ \/ __| 
#  | || | | \__ \ || (_| | | | | |_| | |_) | (_| | (_| | ||  __/\__ \ 
# |___|_| |_|___/\__\__,_|_|_|  \___/| .__/ \__,_|\__,_|\__\___||___/ 
#                                    |_|                              
# by Stephan Raabe (2023) 
# ----------------------------------------------------- 
# Required: yay trizen timeshift btrfs-grub
# ----------------------------------------------------- 

sleep 1
clear

cat <<"EOF"
 _   _           _       _            
| | | |_ __   __| | __ _| |_ ___  ___ 
| | | | '_ \ / _` |/ _` | __/ _ \/ __|
| |_| | |_) | (_| | (_| | ||  __/\__ \
 \___/| .__/ \__,_|\__,_|\__\___||___/
      |_|                             

EOF

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

# ------------------------------------------------------
# Confirm Start
# ------------------------------------------------------

if gum confirm "DO YOU WANT TO START THE UPDATE NOW?" ;then
    echo "Update started."
elif [ $? -eq 130 ]; then
        exit 130
else
    echo "Update canceled."
    exit;
fi
echo ""

if [[ $(_isInstalledYay "Timeshift") == 1 ]] ;then
    if gum confirm "DO YOU WANT TO CREATE A SNAPSHOT?" ;then
        echo ""
        c=$(gum input --placeholder "Enter a comment for the snapshot...")
        sudo timeshift --create --comments "$c"
        sudo timeshift --list
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        echo "DONE. Snapshot $c created!"
        echo ""
    elif [ $? -eq 130 ]; then
        echo "Snapshot canceled."
        exit 130
    else
        echo "Snapshot canceled."
    fi
    echo ""
fi

echo "-----------------------------------------------------"
echo "Start update"
echo "-----------------------------------------------------"
echo ""

yay

notify-send "Update complete"
