#!/usr/bin/env bash
# ==============================================================================
# Wallpaper Initialization & Daemon Starter for Hyprland
# ==============================================================================
set -euo pipefail

CONF="$HOME/.config/hypr/hyprpaper.conf"
mkdir -p "$HOME/.config/hypr"

find_wallpaper() {
    # 1. Existing path in hyprpaper.conf if valid
    if [[ -f "$CONF" ]]; then
        local current
        current="$(grep -E '^preload\s*=' "$CONF" | head -n 1 | awk -F'=' '{print $2}' | xargs || true)"
        if [[ -n "$current" && -f "$current" ]]; then
            echo "$current"
            return 0
        fi
    fi

    # 2. Check user wallpaper directories and system backgrounds
    for dir in "$HOME/Pictures/Wallpapers" "$HOME/.local/share/backgrounds" "$HOME/Pictures" "/usr/share/backgrounds/fedora-workstation" "/usr/share/backgrounds/gnome" "/usr/share/backgrounds"; do
        if [[ -d "$dir" ]]; then
            local img
            img="$(find "$dir" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | grep -v "Screenshots" | head -n 1 || true)"
            if [[ -n "$img" && -f "$img" ]]; then
                echo "$img"
                return 0
            fi
        fi
    done
    return 1
}

WP=""
if WP="$(find_wallpaper)"; then
    cat << EOF > "$CONF"
preload = $WP
wallpaper = ,$WP
splash = false
ipc = true
EOF

    # Apply via swaybg for instant, guaranteed rendering
    if command -v swaybg >/dev/null 2>&1; then
        pkill -x swaybg 2>/dev/null || true
        swaybg -i "$WP" -m fill &
    fi

    # Start hyprpaper daemon
    if command -v hyprpaper >/dev/null 2>&1; then
        pkill -x hyprpaper 2>/dev/null || true
        exec hyprpaper
    fi
else
    # Solid background fallback
    if command -v swaybg >/dev/null 2>&1; then
        exec swaybg -c "1e1e2e"
    elif command -v hyprpaper >/dev/null 2>&1; then
        exec hyprpaper
    fi
fi
