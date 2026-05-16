#!/bin/bash

# Adjust the volume by the specified amount (argument passed to script)
pactl set-sink-volume @DEFAULT_SINK@ "$1"1%

# Capture the updated volume of the default sink and extract the percentage
VOLUME_LEVEL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}')

# Display a two-line notification with Volume level
notify-send -t 1000 -r 998 "Volume" "$VOLUME_LEVEL"
