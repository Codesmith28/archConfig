#!/bin/bash
#  ____                               _           _
# / ___|  ___ _ __ ___  ___ _ __  ___| |__   ___ | |_
# \___ \ / __| '__/ _ \/ _ \ '_ \/ __| '_ \ / _ \| __|
#  ___) | (__| | |  __/  __/ | | \__ \ | | | (_) | |_
# |____/ \___|_|  \___|\___|_| |_|___/_| |_|\___/ \__|
#
#
# by Stephan Raabe (2023)
# -----------------------------------------------------

DIR="$HOME/Pictures/screenshots/"

# get details of what window is open and append it in the screenshot name
NAME="screenshot_$(date +%Y-%m-%d_%H%M%S).png"

grim -g "$(slurp)" "$DIR$NAME"
xclip -selection clipboard -t image/png -i "$DIR$NAME"
swappy -f -
notify-send -t 250 "Screenshot created and copied to clipboard" "Mode: Selected area"

# option2="Selected area"
# option3="Fullscreen"
#
# options="$option2\n$option3"
#
# choice=$(echo -e "$options" | rofi -dmenu -replace -config ~/dotfiles/rofi/config-screenshot.rasi -i -no-show-icons -l 2 -width 30 -p "Take Screenshot")
#
# case $choice in
#     $option2)
#         grim -g "$(slurp)" "$DIR$NAME"
#         xclip -selection clipboard -t image/png -i "$DIR$NAME"
#         swappy -f -
#         notify-send -t 250 "Screenshot created and copied to clipboard" "Mode: Selected area"
#     ;;
#     $option3)
#         sleep 0.75
#         grim "$DIR$NAME"
#         xclip -selection clipboard -t image/png -i "$DIR$NAME"
#         swappy -f -
#         notify-send -t 250 "Screenshot created and copied to clipboard" "Mode: Fullscreen"
#     ;;
# esac
