#!/bin/bash

# Adjust brightness and capture output in one call
OUTPUT=$(brightnessctl set 5%"$1")

# Extract brightness percentage from output (as integer)
BRIGHTNESS=$(echo "$OUTPUT" | grep -oP '\d+(?=%)')

# Use helper script to show progress bar with consistent notification ID (no spam)
$HOME/.config/hypr/scripts/notify-progress.sh "Brightness" 999 "$BRIGHTNESS" &