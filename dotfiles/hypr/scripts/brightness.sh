#!/bin/bash

# Adjust the brightness by a specified amount (passed as an argument)
brightnessctl set 5%"$1"

# Capture the current brightness level and format it
BRIGHTNESS_LEVEL=$(brightnessctl i | grep "Current brightness" | awk '{print $4}' | tr -d '()%')

# Display a two-line notification with brightness level
notify-send -t 1000 -r 999 "Brightness" "$BRIGHTNESS_LEVEL%"
