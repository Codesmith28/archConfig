#!/usr/bin/env bash
# ==============================================================================
# Wayland Native Clipboard History Listener
# ==============================================================================
# Continuously listens for Wayland clipboard events (text and images) via wl-paste.
# Maintains:
# - Full-content preservation in ~/.cache/clipboard/entries/
# - Fast 128x128 image thumbnails in ~/.cache/clipboard/thumbnails/
# - Visual index for Wofi in ~/.cache/clipboard/index.txt
# - Backward-compatible entries in ~/.cache/clipboard_history.txt
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/clipboard"
ENTRIES_DIR="$CACHE_DIR/entries"
THUMBS_DIR="$CACHE_DIR/thumbnails"
INDEX_FILE="$CACHE_DIR/index.txt"
LEGACY_FILE="$HOME/.cache/clipboard_history.txt"
MAX_ENTRIES=100

mkdir -p "$ENTRIES_DIR" "$THUMBS_DIR" 2>/dev/null || {
    CACHE_DIR="/tmp/clipboard"
    ENTRIES_DIR="$CACHE_DIR/entries"
    THUMBS_DIR="$CACHE_DIR/thumbnails"
    INDEX_FILE="$CACHE_DIR/index.txt"
    LEGACY_FILE="$CACHE_DIR/clipboard_history.txt"
    mkdir -p "$ENTRIES_DIR" "$THUMBS_DIR" 2>/dev/null || true
}
touch "$INDEX_FILE" "$LEGACY_FILE" 2>/dev/null || true

if ! command -v wl-paste >/dev/null 2>&1; then
    if [[ -f "$SCRIPT_DIR/clipboard-daemon.py" ]]; then
        exec python3 "$SCRIPT_DIR/clipboard-daemon.py"
    fi
    exit 0
fi

# ------------------------------------------------------------------------------
# Ingest Functions
# ------------------------------------------------------------------------------
store_text() {
    local text="$1"
    [[ -z "${text// }" ]] && return 0

    local hash
    hash="$(printf "%s" "$text" | sha256sum | cut -c 1-16)"
    local entry_file="$ENTRIES_DIR/${hash}.txt"

    # Persist full multi-line text
    printf "%s" "$text" > "$entry_file"

    local line_count
    line_count="$(printf "%s" "$text" | wc -l || echo 1)"
    local byte_count
    byte_count="$(printf "%s" "$text" | wc -c || echo 0)"
    local first_line
    first_line="$(head -n 1 <<< "$text" | tr -d '\r' | cut -c 1-70 | tr ':' ' ')"

    local label
    if [[ "$line_count" -gt 1 ]]; then
        label="${first_line} [${line_count} lines, ${byte_count}B] (${hash})"
    else
        label="${first_line} (${hash})"
    fi

    local index_entry="text:${label}"
    local tmp_idx="$INDEX_FILE.tmp"
    grep -v "(${hash})" "$INDEX_FILE" 2>/dev/null > "$tmp_idx" || true
    (echo "$index_entry"; cat "$tmp_idx") | head -n "$MAX_ENTRIES" > "$INDEX_FILE"
    rm -f "$tmp_idx"

    # Legacy file
    local cleaned_legacy
    cleaned_legacy="$(printf "%s" "$text" | head -c 1000 | tr '\n' ' ' | xargs)"
    if [[ -n "$cleaned_legacy" ]]; then
        local tmp_leg="$LEGACY_FILE.tmp"
        grep -Fxv "$cleaned_legacy" "$LEGACY_FILE" 2>/dev/null > "$tmp_leg" || true
        (echo "$cleaned_legacy"; cat "$tmp_leg") | head -n "$MAX_ENTRIES" > "$LEGACY_FILE"
        rm -f "$tmp_leg"
    fi
}

store_image() {
    local tmp_raw
    tmp_raw="$(mktemp --suffix=.png)"
    cat > "$tmp_raw"

    local file_size
    file_size="$(wc -c < "$tmp_raw" || echo 0)"
    if [[ "$file_size" -lt 64 ]]; then
        rm -f "$tmp_raw"
        return 0
    fi

    local hash
    hash="$(sha256sum "$tmp_raw" | cut -c 1-16)"
    local full_img="$ENTRIES_DIR/${hash}.png"
    local thumb_img="$THUMBS_DIR/${hash}.png"

    mv "$tmp_raw" "$full_img"

    # Generate 128x128 thumbnail
    if command -v magick >/dev/null 2>&1; then
        magick "$full_img" -thumbnail 128x128 "$thumb_img" 2>/dev/null || cp "$full_img" "$thumb_img"
    elif command -v convert >/dev/null 2>&1; then
        convert "$full_img" -thumbnail 128x128 "$thumb_img" 2>/dev/null || cp "$full_img" "$thumb_img"
    else
        python3 -c "from PIL import Image; im=Image.open('$full_img'); im.thumbnail((128,128)); im.save('$thumb_img')" 2>/dev/null || cp "$full_img" "$thumb_img"
    fi

    local dims="Image"
    if command -v identify >/dev/null 2>&1; then
        dims="$(identify -format "%wx%h %m" "$full_img" 2>/dev/null || echo "PNG")"
    fi

    local label="[Image] ${dims} (${hash})"
    local index_entry="img:${thumb_img}:text:${label}"

    local tmp_idx="$INDEX_FILE.tmp"
    grep -v "(${hash})" "$INDEX_FILE" 2>/dev/null > "$tmp_idx" || true
    (echo "$index_entry"; cat "$tmp_idx") | head -n "$MAX_ENTRIES" > "$INDEX_FILE"
    rm -f "$tmp_idx"

    local legacy_entry="[Image ${dims}] (${hash})"
    local tmp_leg="$LEGACY_FILE.tmp"
    grep -v "(${hash})" "$LEGACY_FILE" 2>/dev/null > "$tmp_leg" || true
    (echo "$legacy_entry"; cat "$tmp_leg") | head -n "$MAX_ENTRIES" > "$LEGACY_FILE"
    rm -f "$tmp_leg"
}

export -f store_text store_image
export CACHE_DIR ENTRIES_DIR THUMBS_DIR INDEX_FILE LEGACY_FILE MAX_ENTRIES

# Run watchers concurrently
wl-paste --type text --watch bash -c 'store_text "$(cat)"' &
PID_TEXT=$!

wl-paste --type image --watch bash -c 'store_image' &
PID_IMG=$!

trap 'kill $PID_TEXT $PID_IMG 2>/dev/null || true' EXIT SIGINT SIGTERM
wait
