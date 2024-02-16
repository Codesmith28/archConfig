#!/bin/bash

THEME_CACHE_FILE=~/.cache/.themestyle.sh

# Toggle waybar on and off
if pgrep -x "waybar" > /dev/null; then
    killall waybar
    pkill waybar
    WAYBAR_ENABLED=false
else
    WAYBAR_ENABLED=true
    # Read the current theme information from the cache file
    if [ -f "$THEME_CACHE_FILE" ]; then
        themestyle=$(cat "$THEME_CACHE_FILE")
    else
        touch "$THEME_CACHE_FILE"
        themestyle="/ml4w;/ml4w/light"
        echo "$themestyle" > "$THEME_CACHE_FILE"
    fi

    IFS=';' read -ra arrThemes <<< "$themestyle"

    # Launch Waybar with the correct theme
    if "$WAYBAR_ENABLED" ; then
        waybar -c ~/dotfiles/waybar/themes${arrThemes[0]}/config -s ~/dotfiles/waybar/themes${arrThemes[1]}/style.css &
    fi
fi
