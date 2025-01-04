#!/bin/bash

# Get the active window ID
ACTIVE_WINDOW=$(hyprctl activewindow -j | jq -r '.address')

# check if active window is floating or not
IS_FLOATING=$(hyprctl activewindow -j | jq -r '.floating')

# If the window is not floating, apply floating mode
if [ "$IS_FLOATING" == "false" ]; then
    hyprctl dispatch togglefloating
fi

# Apply floating mode, resize, and center the active window
hyprctl dispatch focuswindow "$ACTIVE_WINDOW"
hyprctl dispatch resizeactive exact 800 600
hyprctl dispatch centerwindow
