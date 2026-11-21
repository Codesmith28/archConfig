#!/usr/bin/env bash

# Script to toggle window floating state and switch between small and large sizes.
# Usage: toggle-float.sh <small_width> <small_height> <large_width> <large_height>

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <small_width> <small_height> <large_width> <large_height>"
    exit 1
fi

SMALL_W=$1
SMALL_H=$2
LARGE_W=$3
LARGE_H=$4

# Ensure jq is available
if ! command -v jq &> /dev/null; then
    notify-send "toggle-float.sh" "jq is required but not installed."
    exit 1
fi

# Check if the active window is already floating
is_floating=$(hyprctl activewindow -j | jq -r '.floating')

if [ "$is_floating" = "false" ]; then
    hyprctl dispatch togglefloating
fi

# Get the current width of the active window
current_width=$(hyprctl activewindow -j | jq -r '.size[0]')

# Threshold to decide which size to use (a bit smaller than large width)
threshold=$(( LARGE_W - 100 ))

if [ "$current_width" -ge "$threshold" ]; then
    # Window is large, resize to small
    hyprctl dispatch resizeactive exact "$SMALL_W" "$SMALL_H"
else
    # Window is small (or intermediate), resize to large
    hyprctl dispatch resizeactive exact "$LARGE_W" "$LARGE_H"
fi

# Center the window on the screen
hyprctl dispatch centerwindow
