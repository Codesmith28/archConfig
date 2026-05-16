#!/bin/bash
#  _____                 _       __        __          _
# |_   _|__   __ _  __ _| | ___  \ \      / /_ _ _   _| |__   __ _ _ __
#   | |/ _ \ / _` |/ _` | |/ _ \  \ \ /\ / / _` | | | | '_ \ / _` | '__|
#   | | (_) | (_| | (_| | |  __/   \ V  V / (_| | |_| | |_) | (_| | |
#   |_|\___/ \__, |\__, |_|\___|    \_/\_/ \__,_|\__, |_.__/ \__,_|_|
#            |___/ |___/                         |___/
#

WAYBAR_DISABLED=~/.cache/waybar-disabled

# Toggle the disabled flag
if [ -f "$WAYBAR_DISABLED" ]; then
    rm "$WAYBAR_DISABLED"
    echo "Waybar re-enabled."
else
    touch "$WAYBAR_DISABLED"
    echo "Waybar disabled."
    pkill -x waybar
    exit 0
fi

# Relaunch Waybar using your launch script
~/.config/waybar/launch.sh &
