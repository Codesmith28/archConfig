#!/bin/bash

# Toggle mute state for the default audio source (microphone)
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Capture the mute status of the default audio source
# Extracts 'true' or 'false' from wpctl output to check if muted
MUTE_STATUS=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -o 'MUTED')

# If 'MUTED' is found in output, it means the microphone is muted
if [ "$MUTE_STATUS" == "MUTED" ]; then
    notify-send -t 1000 -r 999 "Microphone Status" "Muted"
else
    notify-send -t 1000 -r 999 "Microphone Status" "Unmuted"
fi
