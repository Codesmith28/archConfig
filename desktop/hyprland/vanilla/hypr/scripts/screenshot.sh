#!/usr/bin/env bash
# ==============================================================================
# Universal Wayland Screenshot Utility for Hyprland
# High-reliability screen capture powered by grim, slurp, and swappy
# ==============================================================================
set -euo pipefail

# 1. Ensure user binaries are in PATH
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:$PATH"

# 2. Robust Wayland socket discovery
if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

# If WAYLAND_DISPLAY is unset or points to a non-existent socket (e.g. stale wayland-0), auto-resolve
if [[ -z "${WAYLAND_DISPLAY:-}" ]] || [[ ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]; then
    for s in "$XDG_RUNTIME_DIR"/wayland-[0-9]*; do
        if [[ -S "$s" ]]; then
            export WAYLAND_DISPLAY="$(basename "$s")"
            break
        fi
    done
fi

# 3. Robust Hyprland instance signature discovery
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    latest_sig="$(ls -td "$XDG_RUNTIME_DIR"/hypr/* 2>/dev/null | head -n1 | xargs -r basename || true)"
    if [[ -n "$latest_sig" ]]; then
        export HYPRLAND_INSTANCE_SIGNATURE="$latest_sig"
    fi
fi

MODE="${1:-region}"
SCREENSHOT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
TARGET_FILE="$SCREENSHOT_DIR/screenshot_${TIMESTAMP}.png"

play_shutter() {
    canberra-gtk-play -i screen-capture 2>/dev/null || \
    pw-play /usr/share/sounds/freedesktop/stereo/screen-capture.oga 2>/dev/null || \
    aplay -q /usr/share/sounds/freedesktop/stereo/screen-capture.oga 2>/dev/null || true &
}

generate_thumbnail() {
    local src="$1"
    local thumb_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/screenshots/thumbs"
    mkdir -p "$thumb_dir"
    local thumb="$thumb_dir/thumb_$(basename "$src")"

    if command -v magick >/dev/null 2>&1; then
        magick "$src" -thumbnail 240x135 "$thumb" 2>/dev/null && echo "$thumb" && return 0
    elif command -v convert >/dev/null 2>&1; then
        convert "$src" -thumbnail 240x135 "$thumb" 2>/dev/null && echo "$thumb" && return 0
    elif command -v ffmpeg >/dev/null 2>&1; then
        ffmpeg -y -i "$src" -vf "scale=240:-1" "$thumb" >/dev/null 2>&1 && echo "$thumb" && return 0
    elif command -v python3 >/dev/null 2>&1; then
        if python3 -c "from PIL import Image; im=Image.open('$src'); im.thumbnail((240, 135)); im.save('$thumb')" >/dev/null 2>&1; then
            echo "$thumb"
            return 0
        fi
    fi
    echo "$src"
}

notify_screenshot() {
    local file="$1"
    play_shutter
    if [ -f "$file" ] && command -v notify-send >/dev/null 2>&1; then
        local thumb
        thumb="$(generate_thumbnail "$file" 2>/dev/null || echo "$file")"
        local base_file
        base_file="$(basename "$file")"
        local body
        body="$(printf "File:   %s\nFolder: ~/Pictures/Screenshots\nAction: Copied to clipboard" "$base_file")"

        notify-send \
            -a "Screenshot" \
            -r 994 \
            -h "string:x-canonical-private-synchronous:screenshot" \
            -h "string:synchronous:screenshot" \
            -i "$thumb" \
            -t 3500 \
            "Screenshot Captured" \
            "$body" 2>/dev/null || true
    fi
}

copy_to_clipboard() {
    local file="$1"
    if [ -f "$file" ]; then
        if command -v wl-copy >/dev/null 2>&1; then
            wl-copy --type image/png < "$file" 2>/dev/null || true
        elif command -v xclip >/dev/null 2>&1; then
            xclip -selection clipboard -t image/png -i "$file" 2>/dev/null || true
        fi
    fi
}

case "$MODE" in
    menu|--menu)
        options="✂️  Snip Area\n🪟  Active Window\n🖥️  Entire Screen\n✏️  Snip & Annotate (Swappy)\n⏱️  Delayed Snip (5s)"
        choice="$(echo -e "$options" | wofi --dmenu --prompt "Screenshot" --width 340 --lines 6 --location center 2>/dev/null || true)"
        case "$choice" in
            *Area*) "$0" region ;;
            *Window*) "$0" window ;;
            *Entire*) "$0" output ;;
            *Annotate*) "$0" annotate ;;
            *Delayed*) sleep 5 && "$0" output ;;
            *) exit 0 ;;
        esac
        ;;

    region|area|select)
        # Interactive region selection with slurp (transparent background and selection to avoid any tint)
        if command -v slurp >/dev/null 2>&1 && command -v grim >/dev/null 2>&1; then
            geometry="$(slurp -d -b '#00000000' -s '#00000000' -c '#7aa2f7' -w 1 2>/dev/null || true)"
            if [[ -z "$geometry" ]]; then
                # User cancelled (Escape or clicked outside)
                exit 0
            fi
            # Allow compositor to unmap slurp layer surface to ensure clean, untinted capture
            sleep 0.08
            grim -g "$geometry" "$TARGET_FILE"
            copy_to_clipboard "$TARGET_FILE"
            notify_screenshot "$TARGET_FILE"
        else
            grim "$TARGET_FILE"
            copy_to_clipboard "$TARGET_FILE"
            notify_screenshot "$TARGET_FILE"
        fi
        ;;

    window|active)
        # Window capture (prefers active window, falls back to interactive window selection)
        geom=""
        if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
            active_json="$(hyprctl activewindow -j 2>/dev/null || echo "{}")"
            geom="$(echo "$active_json" | jq -r 'if .at and .size then "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])" else "" end' 2>/dev/null || true)"
        fi

        if [[ -z "$geom" || "$geom" == "null,null nullxnull" ]]; then
            if command -v slurp >/dev/null 2>&1 && command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
                clients_boxes="$(hyprctl clients -j 2>/dev/null | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null || true)"
                if [[ -n "$clients_boxes" ]]; then
                    geom="$(slurp -r -b '#00000000' -s '#00000000' -c '#7aa2f7' -w 1 <<< "$clients_boxes" 2>/dev/null || true)"
                    sleep 0.08
                fi
            fi
        fi

        if [[ -n "$geom" ]] && command -v grim >/dev/null 2>&1; then
            grim -g "$geom" "$TARGET_FILE"
            copy_to_clipboard "$TARGET_FILE"
            notify_screenshot "$TARGET_FILE"
        elif command -v grim >/dev/null 2>&1; then
            grim "$TARGET_FILE"
            copy_to_clipboard "$TARGET_FILE"
            notify_screenshot "$TARGET_FILE"
        fi
        ;;

    output|screen|fullscreen)
        if command -v grim >/dev/null 2>&1; then
            grim "$TARGET_FILE"
            copy_to_clipboard "$TARGET_FILE"
            notify_screenshot "$TARGET_FILE"
        fi
        ;;

    annotate|swappy|edit)
        if command -v swappy >/dev/null 2>&1; then
            if command -v slurp >/dev/null 2>&1 && command -v grim >/dev/null 2>&1; then
                geom="$(slurp -d -b '#00000000' -s '#00000000' -c '#7aa2f7' -w 1 2>/dev/null || true)"
                if [[ -z "$geom" ]]; then
                    exit 0
                fi
                sleep 0.08
                grim -g "$geom" "$TARGET_FILE"
                copy_to_clipboard "$TARGET_FILE"
                swappy -f "$TARGET_FILE"
            else
                grim "$TARGET_FILE"
                swappy -f "$TARGET_FILE"
            fi
        else
            "$0" region
        fi
        ;;

    *)
        "$0" region
        ;;
esac
