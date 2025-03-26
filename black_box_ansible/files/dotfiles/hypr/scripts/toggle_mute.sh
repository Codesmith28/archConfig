#!/bin/bash

# Toggle mute state for the default audio sink
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Capture mute status of the default sink
MUTE_STATUS=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED")

# If MUTE_STATUS is empty, it means audio is unmuted
if [ -z "$MUTE_STATUS" ]; then
    MUTE_STATUS="UNMUTED"
else
    MUTE_STATUS="MUTED"
fi

# Send notification with the current audio status in a two-line format
notify-send -r 999 "Audio Status" "$MUTE_STATUS"
