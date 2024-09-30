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
cache_dir="$HOME/.cache/wallpaper_cache"
mkdir -p "$cache_dir"

# Define cache file paths
used_wallpaper="$cache_dir/used_wallpaper"
cache_file="$cache_dir/current_wallpaper"
blurred="$cache_dir/blurred_wallpaper.png"
square="$cache_dir/square_wallpaper.png"
rasi_file="$cache_dir/current_wallpaper.rasi"
blur_file="$HOME/dotfiles/.settings/blur.sh"

wallpaper_folder="$HOME/wallpaper"
if [ -f ~/dotfiles/.settings/wallpaper-folder.sh ]; then
    source ~/dotfiles/.settings/wallpaper-folder.sh
fi

blur="50x30"
blur=$(cat $blur_file)

# Create cache file if it doesn't exist
if [ ! -f $cache_file ]; then
    touch $cache_file
    echo "$wallpaper_folder/default.jpg" >"$cache_file"
fi

# Create rasi file if it doesn't exist
if [ ! -f $rasi_file ]; then
    touch $rasi_file
    echo "* { current-image: url(\"$wallpaper_folder/default.jpg\", height); }" >"$rasi_file"
fi

current_wallpaper=$(cat "$cache_file")

case $1 in

# Load wallpaper from .cache of last session
"init")
    sleep 1
    if [ -f $cache_file ]; then
        swww img $current_wallpaper
    else
        swww img $wallpaper_folder/
    fi
    ;;

# Select wallpaper with rofi
"select")
    sleep 0.2

    selected=$(find "$wallpaper_folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec basename {} \; | sort -R | while read rfile; do
        echo -en "$rfile\x00icon\x1f$wallpaper_folder/${rfile}\n"
    done | rofi -dmenu -i -replace -config ~/dotfiles/rofi/config-wallpaper.rasi)

    if [ ! "$selected" ]; then
        echo "No wallpaper selected"
        exit
    fi

    swww img $wallpaper_folder/$selected \
        --transition-bezier .43,1.19,1,.4 \
        --transition-fps=60 \
        --transition-type="wipe" \
        --transition-duration=0.7 \
        --transition-pos "$(hyprctl cursorpos)"
    ;;

# Randomly select wallpaper
*)
    selected=$(find "$wallpaper_folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort -R | head -n 1)
    swww img $selected
    ;;
esac

# -----------------------------------------------------
# Load current pywal color scheme (if needed for colors)
# -----------------------------------------------------
source "$HOME/.cache/wal/colors.sh"

# -----------------------------------------------------
# Get wallpaper image name
# -----------------------------------------------------
newwall=$(echo $current_wallpaper | sed "s|$wallpaper_folder/||g")

# -----------------------------------------------------
# Reload waybar with new colors
# -----------------------------------------------------
~/dotfiles/waybar/launch.sh

# -----------------------------------------------------
# Set the new wallpaper
# -----------------------------------------------------
transition_type="wipe"
cp $current_wallpaper $cache_dir/
mv $cache_dir/$newwall $used_wallpaper

# Wallpaper Engine Logic
wallpaper_engine=$(cat $HOME/dotfiles/.settings/wallpaper-engine.sh)
if [ "$wallpaper_engine" == "swww" ]; then
    echo ":: Using swww"
    swww img $used_wallpaper \
        --transition-bezier .43,1.19,1,.4 \
        --transition-fps=60 \
        --transition-type=$transition_type \
        --transition-duration=0.7 \
        --transition-pos "$(hyprctl cursorpos)"

elif [ "$wallpaper_engine" == "hyprpaper" ]; then
    echo ":: Using hyprpaper"
    killall hyprpaper
    wal_tpl=$(cat $HOME/dotfiles/.settings/hyprpaper.tpl)
    output=${wal_tpl//WALLPAPER/$used_wallpaper}
    echo "$output" >$HOME/dotfiles/hypr/hyprpaper.conf
    hyprpaper &
else
    echo ":: Wallpaper Engine disabled"
fi

if [ "$1" == "init" ]; then
    echo ":: Init"
else
    sleep 1
    dunstify "Changing wallpaper ..." "with image $newwall" -h int:value:25 -h string:x-dunst-stack-tag:wallpaper
    $HOME/.config/ml4w-hyprland-settings/hyprctl.sh &
fi

# -----------------------------------------------------
# Create blurred wallpaper
# -----------------------------------------------------
if [ "$1" != "init" ]; then
    dunstify "Creating blurred version ..." "with image $newwall" -h int:value:50 -h string:x-dunst-stack-tag:wallpaper
    magick $used_wallpaper -resize 75% $blurred
    if [ ! "$blur" == "0x0" ]; then
        magick $blurred -blur $blur $blurred
    fi
fi

# -----------------------------------------------------
# Create square wallpaper
# -----------------------------------------------------
if [ "$1" != "init" ]; then
    dunstify "Creating square version ..." "with image $newwall" -h int:value:75 -h string:x-dunst-stack-tag:wallpaper
    magick $current_wallpaper -gravity Center -extent 1:1 $square
fi

# -----------------------------------------------------
# Write selected wallpaper into cache files
# -----------------------------------------------------
echo "$current_wallpaper" >"$cache_file"
echo "* { current-image: url(\"$blurred\", height); }" >"$rasi_file"

# -----------------------------------------------------
# Send notification
# -----------------------------------------------------
if [ "$1" != "init" ]; then
    dunstify "Wallpaper procedure complete!" "with image $newwall" -h int:value:100 -h string:x-dunst-stack-tag:wallpaper
fi

echo "DONE!"
