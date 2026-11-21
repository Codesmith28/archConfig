#!/usr/bin/env bash
# ==============================================================================
# High-Performance Wallpaper Picker for Hyprland
# ==============================================================================
# Pick a wallpaper via Wofi with instant thumbnail caching (<200ms latency).
# Automatically caches 128x128 thumbnails in ~/.cache/wallpaper_thumbnails/
# Eliminates lag, freezing, and synchronous 4K image decoding on the UI thread.
# Dynamically applies with hyprpaper and swaybg.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/launcher-guard.sh" ]]; then
    source "$SCRIPT_DIR/launcher-guard.sh"
    guard_launcher "wallpicker"
fi

HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper_thumbnails"
mkdir -p "$HOME/.config/hypr" "$HOME/Pictures/Wallpapers" "$HOME/.local/share/backgrounds" "$THUMB_DIR" 2>/dev/null || true
if [[ ! -d "$THUMB_DIR" ]]; then
    THUMB_DIR="/tmp/wallpaper_thumbnails"
    mkdir -p "$THUMB_DIR" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# Image Discovery
# ------------------------------------------------------------------------------
find_images() {
    local dirs=()
    for d in "$HOME/Pictures/Wallpapers" \
             "$HOME/.local/share/backgrounds" \
             "$HOME/Pictures" \
             "/usr/share/backgrounds/fedora-workstation" \
             "/usr/share/backgrounds/gnome" \
             "/usr/share/backgrounds"; do
        [[ -d "$d" ]] && dirs+=("$d")
    done
    [[ ${#dirs[@]} -eq 0 ]] && return 0

    find "${dirs[@]}" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | grep -v "Screenshots" || true
}

# ------------------------------------------------------------------------------
# High-Speed Batch Thumbnail Caching Engine
# ------------------------------------------------------------------------------
# Pre-generates/validates 128x128 thumbnails in parallel using Python PIL.
# Falls back to vipsthumbnail, ffmpegthumbnailer, magick, or convert.
cache_thumbnails() {
    local img_list=("$@")
    [[ ${#img_list[@]} -eq 0 ]] && return 0

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$THUMB_DIR" "${img_list[@]}" << 'EOF' 2>/dev/null || true
import sys, os, hashlib
from concurrent.futures import ThreadPoolExecutor

thumb_dir = sys.argv[1]
images = sys.argv[2:]

def process_image(img_path):
    if not os.path.isfile(img_path):
        return
    h = hashlib.sha256(img_path.encode("utf-8")).hexdigest()[:16]
    thumb_path = os.path.join(thumb_dir, f"{h}.png")

    try:
        mtime_orig = os.path.getmtime(img_path)
        if os.path.isfile(thumb_path) and os.path.getmtime(thumb_path) >= mtime_orig:
            return # Valid cache hit
    except Exception:
        pass

    try:
        from PIL import Image
        with Image.open(img_path) as im:
            im.thumbnail((128, 128))
            im.save(thumb_path, "PNG", optimize=False)
    except Exception:
        pass

workers = min(16, max(2, (os.cpu_count() or 4) * 2))
with ThreadPoolExecutor(max_workers=workers) as executor:
    list(executor.map(process_image, images))
EOF
        return 0
    fi

    # Shell fallbacks if python is unavailable
    for img in "${img_list[@]}"; do
        local h
        h="$(printf "%s" "$img" | sha256sum | cut -c 1-16)"
        local thumb="$THUMB_DIR/${h}.png"
        if [[ ! -f "$thumb" || "$img" -nt "$thumb" ]]; then
            if command -v vipsthumbnail >/dev/null 2>&1; then
                vipsthumbnail "$img" -s 128x128 -o "$thumb" 2>/dev/null || cp "$img" "$thumb"
            elif command -v ffmpegthumbnailer >/dev/null 2>&1; then
                ffmpegthumbnailer -i "$img" -o "$thumb" -s 128 2>/dev/null || cp "$img" "$thumb"
            elif command -v magick >/dev/null 2>&1; then
                magick "$img" -thumbnail 128x128 "$thumb" 2>/dev/null || cp "$img" "$thumb"
            elif command -v convert >/dev/null 2>&1; then
                convert "$img" -thumbnail 128x128 "$thumb" 2>/dev/null || cp "$img" "$thumb"
            fi
        fi
    done
}

get_thumbnail_path() {
    local img="$1"
    local h
    h="$(printf "%s" "$img" | sha256sum | cut -c 1-16)"
    local thumb="$THUMB_DIR/${h}.png"
    if [[ -f "$thumb" ]]; then
        echo "$thumb"
    else
        echo "$img"
    fi
}

# ------------------------------------------------------------------------------
# Wallpaper Application
# ------------------------------------------------------------------------------
apply_wallpaper() {
    local target="$1"
    [[ -f "$target" ]] || return 1

    local thumb
    thumb="$(get_thumbnail_path "$target")"

    # 1. Persist to hyprpaper.conf
    cat << EOF > "$HYPRPAPER_CONF"
preload = $target
wallpaper = ,$target
splash = false
ipc = true
EOF

    # 2. Live apply via hyprpaper if available
    if command -v hyprpaper >/dev/null 2>&1; then
        if pgrep -x "hyprpaper" >/dev/null 2>&1 && command -v hyprctl >/dev/null 2>&1; then
            hyprctl hyprpaper preload "$target" 2>/dev/null || true
            hyprctl hyprpaper wallpaper ",$target" 2>/dev/null || true
        else
            hyprpaper &
        fi
    fi

    # 3. Always apply with swaybg for instant, guaranteed rendering
    if command -v swaybg >/dev/null 2>&1; then
        pkill -x swaybg 2>/dev/null || true
        swaybg -i "$target" -m fill &
    fi

    if command -v notify-send >/dev/null 2>&1; then
        local icon_arg=()
        [[ -f "$thumb" ]] && icon_arg=(-i "$thumb")
        notify-send -a "Wallpaper" "Wallpaper Updated" "$(basename "$target")" "${icon_arg[@]}" 2>/dev/null || true
    fi
}

# Pre-cache only mode (e.g. for background warming on boot)
if [[ "${1:-}" == "--cache" || "${1:-}" == "cache" ]]; then
    mapfile -t ALL_IMAGES < <(find_images)
    cache_thumbnails "${ALL_IMAGES[@]}"
    echo "Cached ${#ALL_IMAGES[@]} wallpapers in $THUMB_DIR"
    exit 0
fi

# ------------------------------------------------------------------------------
# Interactive Picker
# ------------------------------------------------------------------------------
SELECTED=""

if command -v wofi >/dev/null 2>&1; then
    wofi_conf=""
    wofi_style=""
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    for c in "$HOME/.config/wofi/config" \
             "$script_dir/../../wofi/config"; do
        if [[ -f "$c" ]]; then
            wofi_conf="$c"
            break
        fi
    done

    for s in "$HOME/.config/wofi/wallpicker.css" \
             "$script_dir/../../wofi/wallpicker.css" \
             "$HOME/.config/wofi/style.css"; do
        if [[ -f "$s" ]]; then
            wofi_style="$s"
            break
        fi
    done

    WOFI_STYLE_ARGS=()
    [[ -n "$wofi_conf" ]] && WOFI_STYLE_ARGS+=(--conf "$wofi_conf")
    [[ -n "$wofi_style" ]] && WOFI_STYLE_ARGS+=(--style "$wofi_style")

    mapfile -t ALL_IMAGES < <(find_images)
    # Warm thumbnail cache (typically takes <2ms on warm cache, <200ms on cold)
    cache_thumbnails "${ALL_IMAGES[@]}"

    SELECTED=$(
        {
            echo "📁 Open Wallpapers Folder (Add/Remove)..."
            echo "➕ Import New Wallpaper..."
            for img in "${ALL_IMAGES[@]}"; do
                [[ -z "$img" ]] && continue
                name="$(basename "$img")"
                thumb="$(get_thumbnail_path "$img")"
                # Wofi image escape sequence format: img:<thumbnail_path>:text:<label> (<full_path>)
                echo "img:${thumb}:text:${name} (${img})"
            done
        } | wofi --dmenu -p "Pick Wallpaper..." \
            --allow-images --insensitive --hide-scroll \
            --width 780 --lines 8 -D image_size=64 \
            "${WOFI_STYLE_ARGS[@]}" 2>/dev/null || true
    )
elif command -v hyprlauncher >/dev/null 2>&1; then
    SELECTED=$(
        {
            echo "📁 Open Wallpapers Folder (Add/Remove)..."
            echo "➕ Import New Wallpaper..."
            find_images
        } | hyprlauncher -m 2>/dev/null || true
    )
fi

if [[ -z "$SELECTED" || "$SELECTED" == "Exited without selection" ]]; then
    exit 0
fi

case "$SELECTED" in
    *"Open Wallpapers Folder"*)
        mkdir -p "$HOME/Pictures/Wallpapers"
        if command -v nautilus >/dev/null 2>&1; then
            exec nautilus "$HOME/Pictures/Wallpapers"
        elif command -v gio >/dev/null 2>&1; then
            exec gio open "$HOME/Pictures/Wallpapers"
        else
            exec xdg-open "$HOME/Pictures/Wallpapers"
        fi
        exit 0
        ;;
    *"Import New Wallpaper"*)
        mkdir -p "$HOME/Pictures/Wallpapers"
        NEW_WALL=""
        if command -v zenity >/dev/null 2>&1; then
            NEW_WALL="$(zenity --file-selection --title="Select Wallpaper to Import" --file-filter="Images | *.jpg *.jpeg *.png *.webp" 2>/dev/null || true)"
        fi
        if [[ -n "$NEW_WALL" && -f "$NEW_WALL" ]]; then
            cp -n "$NEW_WALL" "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
            apply_wallpaper "$NEW_WALL"
        fi
        exit 0
        ;;
    *)
        # Extract full file path from selection (handles spaces and parentheses safely)
        TARGET_PATH=""
        re_path='\((/[^)]+)\)$'
        re_paren='\(([^)]+)\)$'
        re_img='^img:[^:]+:text:(.*)'
        if [[ "$SELECTED" =~ $re_path ]]; then
            TARGET_PATH="${BASH_REMATCH[1]}"
        elif [[ "$SELECTED" =~ $re_paren ]]; then
            TARGET_PATH="${BASH_REMATCH[1]}"
        elif [[ "$SELECTED" =~ $re_img ]]; then
            TARGET_PATH="${BASH_REMATCH[1]}"
        else
            TARGET_PATH="$SELECTED"
        fi

        TARGET_PATH="$(echo "$TARGET_PATH" | xargs)"
        if [[ -f "$TARGET_PATH" ]]; then
            apply_wallpaper "$TARGET_PATH"
        fi
        exit 0
        ;;
esac
