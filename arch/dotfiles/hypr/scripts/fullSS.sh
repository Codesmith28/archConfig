
#!/bin/bash
#   __       _ _ ____ ____
#  / _|_   _| | / ___/ ___|
# | |_| | | | | \___ \___ \
# |  _| |_| | | |___) |__) |
# |_|  \__,_|_|_|____/____/
# -----------------------------------------------------

DIR="$HOME/Pictures/Screenshots/"

NAME="Screenshot_$(date +%Y-%m-%d_%H%M%S).png"

# Take a fullscreen screenshot using grim
grim "$DIR$NAME"

# Copy the screenshot to the clipboard using wl-copy
wl-copy < "$DIR$NAME"

# Send a notification
notify-send -t 500 "Screenshot created" "Mode: Fullscreen"
