#!/bin/bash

# count the number of clients using hyprctl client and update the number of lines shown in rofi
# at minimum 3 lines will be shown
# at maximum 5 lines will be shown

lines=$(hyprctl client)
if [ $lines -lt 3 ]; then
    lines=3
elif [ $lines -gt 5 ]; then
    lines=5
fi

rofi -show window -l "$lines" -config /home/codesmith28/dotfiles/rofi/config-window.rasi
