#!/bin/bash
#  ____
# |  _ \ _____      _____ _ __ _ __ ___   ___ _ __  _   _
# | |_) / _ \ \ /\ / / _ \ '__| '_ ` _ \ / _ \ '_ \| | | |
# |  __/ (_) \ V  V /  __/ |  | | | | | |  __/ | | | |_| |
# |_|   \___/ \_/\_/ \___|_|  |_| |_| |_|\___|_| |_|\__,_|
#
#
# by Codesmith28
# -----------------------------------------------------
echo $XDG_SESSION_TYPE
lockapp=slock
echo "Using $lockapp to lock the screen."

option1="  lock" #shortcut: l
option2="󰒲  sleep" #shortcut: z
option3="  logout" #shortcut: e
option4="  reboot" #shortcut: r
option5="  power off" #shortcut: s

options="$option1\n"
options="$options$option2\n"
options="$options$option3\n$option4"
options="$options\n$option5"

choice=$(echo -e "$options" | rofi -dmenu -replace -config ~/dotfiles/rofi/config-power.rasi -i -no-show-icons -l 5 -width 30 -p "Powermenu")

case $choice in
    $option1)
    $HOME/dotfiles/hypr/scripts/power.sh lock ;;
    $option2)
    $HOME/dotfiles/hypr/scripts/power.sh suspend ;;
    $option3)
    $HOME/dotfiles/hypr/scripts/power.sh exit ;;
    $option4)
    $HOME/dotfiles/hypr/scripts/power.sh reboot ;;
    $option5)
    $HOME/dotfiles/hypr/scripts/power.sh shutdown ;;
esac
