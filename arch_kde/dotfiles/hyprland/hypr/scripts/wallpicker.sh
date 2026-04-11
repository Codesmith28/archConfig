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
SELECTED_NAME=$(
    fd -a -e jpg -e jpeg -e png -e gif . "$WALLPAPER_DIR" | while read -r img; do
        name=$(basename "$img")
        # Send filename and icon info to rofi
        echo -en "$name\0icon\x1f$img\n"
    done | "$HOME/.config/hypr/scripts/rofi-menu.sh" dmenu "Pick a Wallpaper" \
        -theme-str '
            window {width: 70%;}
            listview {columns: 5; lines: 4; spacing: 10px; flow: horizontal;}
            element {orientation: vertical; padding: 6px; border-radius: 8px; background-color: rgba(10, 10, 10, 74%);}
            element selected {background-color: rgba(30, 30, 30, 86%);}
            element-icon {size: 8em; horizontal-align: 0.5; vertical-align: 0.5;}
            element-text {horizontal-align: 0.5; padding: 4px;}
        '
)

if [ -n "$SELECTED_NAME" ]; then
    # Recover the full path from the selected filename
    SELECTED=$(fd -a -F "$SELECTED_NAME" "$WALLPAPER_DIR" | head -n 1)
    
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
fi
