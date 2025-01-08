#!/bin/bash
#                _ _
# __      ____ _| | |_ __   __ _ _ __   ___ _ __
# \ \ /\ / / _` | | | '_ \ / _` | '_ \ / _ \ '__|
#  \ V  V / (_| | | | |_) | (_| | |_) |  __/ |
#   \_/\_/ \__,_|_|_| .__/ \__,_| .__/ \___|_|
#                   |_|         |_|
#
# by Stephan Raabe (2024)
# -----------------------------------------------------

# Cache directory for holding all cache-related files
cache_dir="$HOME/dotfiles/wallpaper_cache"
mkdir -p "$cache_dir"

# Define cache file paths
used_wallpaper="$cache_dir/used_wallpaper"
cache_file="$cache_dir/current_wallpaper"wallpaper.sh
blurred="$cache_dir/blurred_wallpaper.png"
square="$cache_dir/square_wallpaper.png"
rasi_file="$cache_dir/current_wallpaper.rasi"
blur_file="$HOME/dotfiles/.settings/blur.sh"

wallpaper_folder="$HOME/wallpaper"
if [ -f ~/dotfiles/.settings/wallpaper-folder.sh ]; then
    source ~/dotfiles/.settings/wallpaper-folder.sh
fi

# Load the blur settings
blur=$(cat "$blur_file" 2>/dev/null || echo "50x30")

# Create cache file if it doesn't exist
if [ ! -f "$cache_file" ]; then
    touch "$cache_file"
    echo "$wallpaper_folder/default.jpg" > "$cache_file"
fi

# Create rasi file if it doesn't exist
if [ ! -f "$rasi_file" ]; then
    touch "$rasi_file"
    echo "* { current-image: url(\"$wallpaper_folder/default.jpg\", height); }" > "$rasi_file"
fi

current_wallpaper=$(cat "$cache_file")

case $1 in
    # Load wallpaper from .cache of last session
    "init")
        if [ -f "$cache_file" ]; then
            wal -q -i "$current_wallpaper" || swww img "$current_wallpaper"
        else
            wal -q -i "$current_wallpaper" || swww img "$wallpaper_folder/default.jpg"
        fi
    ;;

    # Select wallpaper with rofi
    "select")
        selected=$(find "$wallpaper_folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
            -exec basename {} \; | sort -R | while read -r rfile; do
                echo -en "$rfile\x00icon\x1f$wallpaper_folder/${rfile}\n"
            done | rofi -dmenu -i -replace -config ~/dotfiles/rofi/config-wallpaper.rasi)

        if [ -z "$selected" ]; then
            echo "No wallpaper selected"
            exit 1
        fi

        current_wallpaper="$wallpaper_folder/$selected"
        wal -q -i "$current_wallpaper" ||
            swww img "$current_wallpaper" \
            --transition-bezier .43,1.19,1,.4 \
            --transition-fps=60 \
            --transition-type="wipe" \
            --transition-duration=0.7 \
            --transition-pos "$(hyprctl cursorpos)"
    ;;

    # Randomly select wallpaper
    *)
        current_wallpaper=$(find "$wallpaper_folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort -R | head -n 1)
        wal -q -i "$current_wallpaper" || swww img "$current_wallpaper"
    ;;
esac

# -----------------------------------------------------# Create folder with generated versions of wallpaper if not exists
# Load pywal color scheme if needed
# -----------------------------------------------------
source "$HOME/.cache/wal/colors.sh"
source "$HOME/dotfiles/hypr/scripts/cachecol.sh"

# -----------------------------------------------------
# Get the wallpaper name for notifications/logging
# -----------------------------------------------------
newwall=$(basename "$current_wallpaper")

# -----------------------------------------------------
# Reload Waybar (if necessary) with new colors
# -----------------------------------------------------
~/dotfiles/waybar/launch.sh

# -----------------------------------------------------
# Set the wallpaper using swww or hyprpaper
# -----------------------------------------------------
cp "$current_wallpaper" "$cache_dir/"
mv "$cache_dir/$newwall" "$used_wallpaper"

wallpaper_engine=$(cat "$HOME/dotfiles/.settings/wallpaper-engine.sh")
if [ "$wallpaper_engine" == "swww" ]; then
    echo ":: Using swww"
    swww img "$used_wallpaper" \
        --transition-bezier .43,1.19,1,.4 \
        --transition-fps=60 \
        --transition-type="wipe" \
        --transition-duration=0.7 \
        --transition-pos "$(hyprctl cursorpos)"
elif [ "$wallpaper_engine" == "hyprpaper" ]; then
    echo ":: Using hyprpaper"
    killall hyprpaper
    wal_tpl=$(cat "$HOME/dotfiles/.settings/hyprpaper.tpl")
    output=${wal_tpl//WALLPAPER/$used_wallpaper}
    echo "$output" > "$HOME/dotfiles/hypr/hyprpaper.conf"
    hyprpaper &
else
    echo ":: Wallpaper Engine disabled"
fi

# -----------------------------------------------------
# Notifications and additional actions
# -----------------------------------------------------
if [ "$1" == "init" ]; then
    echo ":: Init"
else
    sleep 1
    dunstify "Changing wallpaper ..." "with image $newwall" -h int:value:25 -h string:x-dunst-stack-tag:wallpaper
    "$HOME/.config/ml4w-hyprland-settings/hyprctl.sh" &
fi

# -----------------------------------------------------
# Create blurred wallpaper if not "init"
# -----------------------------------------------------

# if [ "$1" != "init" ]; then
#     dunstify "Creating blurred version ..." "with image $newwall" -h int:value:50 -h string:x-dunst-stack-tag:wallpaper
#     if magick "$used_wallpaper" -resize 75% "$blurred" && [ "$blur" != "0x0" ]; then
#         magick "$blurred" -blur "$blur" "$blurred"
#     else
#         echo "Failed to create blurred wallpaper"
#     fi
# fi

if [ "$1" != "init" ]; then
    dunstify "Creating blurred version ..." "with image $newwall" -h int:value:50 -h string:x-dunst-stack-tag:wallpaper
    if magick "$used_wallpaper" -resize 75% "$blurred" && [ "$blur" != "0x0" ]; then
        magick "$blurred" -blur "$blur" "$blurred"
        # Add a slight black tint
        magick "$blurred" -fill "black" -colorize 50% "$blurred"
    else
        echo "Failed to create blurred wallpaper"
    fi
fi

# -----------------------------------------------------
# Create square wallpaper if not "init"
# -----------------------------------------------------
if [ "$1" != "init" ]; then
    dunstify "Creating square version ..." "with image $newwall" -h int:value:75 -h string:x-dunst-stack-tag:wallpaper
    magick "$current_wallpaper" -gravity Center -extent 1:1 "$square"
fi

# -----------------------------------------------------
# Write selected wallpaper to cache files
# -----------------------------------------------------
echo "$current_wallpaper" > "$cache_file"
echo "* { current-image: url(\"$blurred\", height); }" > "$rasi_file"

# -----------------------------------------------------
# Final notification
# -----------------------------------------------------
if [ "$1" != "init" ]; then
    dunstify "Wallpaper procedure complete!" "with image $newwall" -h int:value:100 -h string:x-dunst-stack-tag:wallpaper
fi

echo "DONE!"
