#!/bin/bash

# Get current mode
current_mode=$(powerprofilesctl get)

# Define the mode order
if [ "$current_mode" = "performance" ]; then
    next_mode="power-saver"
elif [ "$current_mode" = "balanced" ]; then
    next_mode="performance"
elif [ "$current_mode" = "power-saver" ]; then
    next_mode="balanced"
else
    notify-send "Power Mode" "Unknown mode: $current_mode"
    exit 1
fi

# Set the new mode
powerprofilesctl set "$next_mode"

# Notify user
# notify-send -t 500 "Power Mode" "Switched to: $next_mode"
# zenity --notification --text="Power mode: $next_mode"
