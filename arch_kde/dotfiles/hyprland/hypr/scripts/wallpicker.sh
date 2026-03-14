#!/usr/bin/env bash
# Pick a wallpaper via rofi dmenu and apply it with hyprpaper.

WALLPAPER_DIR="$HOME/wallpaper/src"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Ensure hyprpaper config file exists
if [ ! -f "$HYPRPAPER_CONF" ]; then
    mkdir -p "$HOME/.config/hypr"
    touch "$HYPRPAPER_CONF"
fi

# Use fd to get all images, pass to rofi dmenu, pick one
SELECTED=$(fd -e jpg -e jpeg -e png -e gif . "$WALLPAPER_DIR" | "$HOME/.config/hypr/scripts/rofi-menu.sh" dmenu "Pick a Wallpaper")

if [ -n "$SELECTED" ]; then
    # Start hyprpaper if it's not running
    if ! pgrep -x "hyprpaper" > /dev/null; then
        hyprpaper &
        sleep 1
    fi
    
    # Send the wallpaper to hyprpaper dynamically
    hyprctl hyprpaper preload "$SELECTED"
    MONITORS=$(hyprctl monitors -j | jq -r '.[].name')
    for m in $MONITORS; do
        hyprctl hyprpaper wallpaper "$m,$SELECTED"
    done
    hyprctl hyprpaper unload all
    
    # Save to config so it persists on next boot
    echo "preload = $SELECTED" > "$HYPRPAPER_CONF"
    for m in $MONITORS; do
        echo "wallpaper = $m,$SELECTED" >> "$HYPRPAPER_CONF"
    done
fi
