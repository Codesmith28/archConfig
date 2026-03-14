#!/bin/bash

# Adjust volume and show notification with progress bar (same notification ID = no spam)
action="${1:-5%+}"
wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "$action"

# Get current volume level (as integer percentage)
VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2 * 100}')

# Check if muted
if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
  notify-send \
    -h "string:x-canonical-private-synchronous:volume" \
    -t 1000 \
    -r 998 \
    "Volume" \
    "Muted" &
else
  # Use helper script to show progress bar with consistent notification ID
  $HOME/.config/hypr/scripts/notify-progress.sh "Volume" 998 "$VOLUME" &
fi

