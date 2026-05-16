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

DIR="$HOME/Pictures/Screenshots/"

# Get details of what window is open and append it in the screenshot name
NAME="Screenshot_$(date +%Y-%m-%d_%H%M%S).png"

# Take a screenshot using grim and slurp
grim -g "$(slurp)" "$DIR$NAME"

# Copy the screenshot to the clipboard using wl-copy
wl-copy < "$DIR$NAME"

# Open the screenshot with swappy for further editing
# swappy -f "$DIR$NAME"

# Send a notification
notify-send -t 500 "Screenshot created and copied to clipboard" "Mode: Selected area"
