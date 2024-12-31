#!/bin/bash

# Get the active window ID
ACTIVE_WINDOW=$(hyprctl activewindow -j | jq -r '.address')

# Apply floating mode, resize, and center the active window
hyprctl dispatch focuswindow "$ACTIVE_WINDOW"
hyprctl dispatch resizeactive exact 800 600
hyprctl dispatch centerwindow
