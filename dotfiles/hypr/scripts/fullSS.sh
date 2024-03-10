#!/bin/bash
#   __       _ _ ____ ____
#  / _|_   _| | / ___/ ___|
# | |_| | | | | \___ \___ \
# |  _| |_| | | |___) |__) |
# |_|  \__,_|_|_|____/____/
# -----------------------------------------------------

DIR="$HOME/Pictures/screenshots/"

NAME="screenshot_$(date +%Y-%m-%d_%H%M%S).png"

grim "$DIR$NAME"
# notify-send "Screenshot created" "Mode: Fullscreen"

# Copy the screenshot to the clipboard
xclip -selection clipboard -t image/png -i "$DIR$NAME"
