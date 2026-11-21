#!/usr/bin/env bash
# ==============================================================================
# Wayland Clipboard History Manager Launcher
# ==============================================================================
# Accessible via Super + V
# Interactive fuzzy selection via Wofi or Clipse, copying directly into Wayland clipboard
# Supports:
# - Clipse TUI mode with image previews (kitty protocol)
# - Wofi / Cliphist visual mode with 128x128 image thumbnails and multi-line stats
# - Interactive preview browser via Super + V or --preview (clipboard-preview.sh)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/clipboard"
ENTRIES_DIR="$CACHE_DIR/entries"
THUMBS_DIR="$CACHE_DIR/thumbnails"
INDEX_FILE="$CACHE_DIR/index.txt"
LEGACY_FILE="$HOME/.cache/clipboard_history.txt"

mkdir -p "$CACHE_DIR" "$ENTRIES_DIR" "$THUMBS_DIR" 2>/dev/null || {
    CACHE_DIR="/tmp/clipboard"
    ENTRIES_DIR="$CACHE_DIR/entries"
    THUMBS_DIR="$CACHE_DIR/thumbnails"
    INDEX_FILE="$CACHE_DIR/index.txt"
    LEGACY_FILE="$CACHE_DIR/clipboard_history.txt"
    mkdir -p "$CACHE_DIR" "$ENTRIES_DIR" "$THUMBS_DIR" 2>/dev/null || true
}
touch "$INDEX_FILE" "$LEGACY_FILE" 2>/dev/null || true

if [[ -f "$SCRIPT_DIR/launcher-guard.sh" ]]; then
    source "$SCRIPT_DIR/launcher-guard.sh"
    guard_launcher "clipboard"
fi

# ------------------------------------------------------------------------------
# Argument Routing
# ------------------------------------------------------------------------------
FORCE_WOFI=false
FORCE_CLIPSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--preview|--tui)
            exec "$SCRIPT_DIR/clipboard-preview.sh" --interactive
            ;;
        -w|--wofi)
            FORCE_WOFI=true
            shift
            ;;
        -c|--clipse)
            FORCE_CLIPSE=true
            shift
            ;;
        --clear)
            rm -rf "${ENTRIES_DIR:?}"/* "${THUMBS_DIR:?}"/*
            > "$INDEX_FILE"
            > "$LEGACY_FILE"
            if command -v cliphist >/dev/null 2>&1; then
                cliphist wipe 2>/dev/null || true
            fi
            if command -v notify-send >/dev/null 2>&1; then
                notify-send -a "Clipboard" "Clipboard Cleared" "All history deleted" -i edit-clear 2>/dev/null || true
            fi
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# ------------------------------------------------------------------------------
# 1. Clipse TUI Workflow (if installed and not forced to Wofi)
# ------------------------------------------------------------------------------
if command -v clipse >/dev/null 2>&1 && [[ "$FORCE_WOFI" == "false" ]]; then
    if ! pgrep -x clipse >/dev/null 2>&1; then
        clipse -listen &
    fi
    if command -v ghostty >/dev/null 2>&1; then
        exec ghostty --class=small_float --title=clipse -e clipse "$@"
    elif command -v ptyxis >/dev/null 2>&1; then
        exec ptyxis --title=clipse -- clipse "$@"
    elif command -v kitty >/dev/null 2>&1; then
        exec kitty --class=small_float --title=clipse clipse "$@"
    else
        exec clipse "$@"
    fi
fi

# ------------------------------------------------------------------------------
# 2. Ensure Background Daemon is running
# ------------------------------------------------------------------------------
if ! pgrep -f "clipboard-daemon" >/dev/null 2>&1; then
    if [[ -x "$SCRIPT_DIR/clipboard-daemon.sh" ]]; then
        "$SCRIPT_DIR/clipboard-daemon.sh" &
    elif [[ -f "$SCRIPT_DIR/clipboard-daemon.py" ]]; then
        python3 "$SCRIPT_DIR/clipboard-daemon.py" &
    fi
fi

# ------------------------------------------------------------------------------
# 3. Resolve Wofi Config & Theme
# ------------------------------------------------------------------------------
wofi_conf=""
wofi_style=""
for c in "$HOME/.config/wofi/config" \
         "$SCRIPT_DIR/../../wofi/config"; do
    if [[ -f "$c" ]]; then
        wofi_conf="$c"
        break
    fi
done

for s in "$HOME/.config/wofi/style.css" \
         "$SCRIPT_DIR/../../wofi/style.css"; do
    if [[ -f "$s" ]]; then
        wofi_style="$s"
        break
    fi
done

WOFI_ARGS=()
[[ -n "$wofi_conf" ]] && WOFI_ARGS+=(--conf "$wofi_conf")
[[ -n "$wofi_style" ]] && WOFI_ARGS+=(--style "$wofi_style")

# ------------------------------------------------------------------------------
# 4. Cliphist Integration (if installed)
# ------------------------------------------------------------------------------
if command -v cliphist >/dev/null 2>&1; then
    # Generate cached thumbnails for any image entries in cliphist list
    generate_cliphist_items() {
        local re_cliphist_img='^([0-9]+)[[:space:]]+\[\[[[:space:]]*binary[[:space:]]*data'
        cliphist list 2>/dev/null | while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if [[ "$line" =~ $re_cliphist_img ]]; then
                local id="${BASH_REMATCH[1]}"
                local thumb="$THUMBS_DIR/cliphist_${id}.png"
                if [[ ! -f "$thumb" ]]; then
                    if command -v magick >/dev/null 2>&1; then
                        cliphist decode "$id" 2>/dev/null | magick - -thumbnail 128x128 "$thumb" 2>/dev/null || true
                    elif command -v convert >/dev/null 2>&1; then
                        cliphist decode "$id" 2>/dev/null | convert - -thumbnail 128x128 "$thumb" 2>/dev/null || true
                    fi
                fi
                if [[ -f "$thumb" ]]; then
                    echo "img:${thumb}:text:${line}"
                else
                    echo "text:${line}"
                fi
            else
                echo "text:${line}"
            fi
        done
    }

    SELECTED="$(generate_cliphist_items | wofi --dmenu -p "Clipboard..." \
        --allow-images --insensitive --hide-scroll \
        --width=780 --lines=12 "${WOFI_ARGS[@]}" 2>/dev/null || true)"

    if [[ -n "$SELECTED" ]]; then
        raw_line="$(echo "$SELECTED" | sed -e 's/^img:[^:]*:text://' -e 's/^text://')"
        local re_clip_id='^([0-9]+)[[:space:]]'
        if [[ "$raw_line" =~ $re_clip_id ]]; then
            clip_id="${BASH_REMATCH[1]}"
            cliphist decode "$clip_id" | wl-copy
            if command -v notify-send >/dev/null 2>&1; then
                notify-send -a "Clipboard" "Copied to Clipboard" "Item #$clip_id copied" -i edit-paste 2>/dev/null || true
            fi
        fi
    fi
    exit 0
fi

# ------------------------------------------------------------------------------
# 5. Visual Wofi Daemon Integration
# ------------------------------------------------------------------------------
# Build items list: prefer index.txt if available, else legacy history
build_items() {
    if [[ -f "$INDEX_FILE" && -s "$INDEX_FILE" ]]; then
        cat "$INDEX_FILE"
    elif [[ -f "$LEGACY_FILE" && -s "$LEGACY_FILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            echo "text:$line"
        done < "$LEGACY_FILE"
    else
        echo "text:Welcome to Clipboard Manager! (Empty history)"
    fi
}

SELECTED="$(build_items | wofi --dmenu -p "Clipboard..." \
    --allow-images --insensitive --hide-scroll \
    --width=780 --lines=12 "${WOFI_ARGS[@]}" 2>/dev/null || true)"

if [[ -z "$SELECTED" || "$SELECTED" == *"Empty history"* ]]; then
    exit 0
fi

# Extract hash or text
re_entry_hash='\(([a-f0-9]{12,64})\)'
if [[ "$SELECTED" =~ $re_entry_hash ]]; then
    HASH="${BASH_REMATCH[1]}"
    if [[ -f "$ENTRIES_DIR/${HASH}.png" ]]; then
        wl-copy --type image/png < "$ENTRIES_DIR/${HASH}.png"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "Clipboard" "Copied Image to Clipboard" "Image restored" -i "$THUMBS_DIR/${HASH}.png" 2>/dev/null || true
        fi
        exit 0
    elif [[ -f "$ENTRIES_DIR/${HASH}.txt" ]]; then
        wl-copy < "$ENTRIES_DIR/${HASH}.txt"
        summary="$(head -n 1 "$ENTRIES_DIR/${HASH}.txt" | cut -c 1-60)"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "Clipboard" "Copied to Clipboard" "$summary" -i edit-paste 2>/dev/null || true
        fi
        exit 0
    fi
fi

# Direct text copy fallback
CLEANED_TEXT="$(echo "$SELECTED" | sed -e 's/^img:[^:]*:text://' -e 's/^text://' | sed -e 's/ ([a-f0-9]\{12,64\})$//')"
if command -v wl-copy >/dev/null 2>&1; then
    printf "%s" "$CLEANED_TEXT" | wl-copy
elif command -v xclip >/dev/null 2>&1; then
    printf "%s" "$CLEANED_TEXT" | xclip -selection clipboard
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Clipboard" "Copied to Clipboard" "$CLEANED_TEXT" -i edit-paste 2>/dev/null || true
fi
exit 0
