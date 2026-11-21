#!/usr/bin/env bash
# ==============================================================================
# Clipboard History Previewer & Interactive Browser
# ==============================================================================
# Provides rich visual preview for clipboard items:
# - Multi-line formatted text with line numbers and syntax highlighting (via bat)
# - High-fidelity image thumbnails and full renders (via previewer.sh)
# - Interactive split-pane TUI browser (fzf + previewer)
# - Direct integration with clipse, cliphist, and wofi daemons
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREVIEWER="$SCRIPT_DIR/previewer.sh"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/clipboard"
ENTRIES_DIR="$CACHE_DIR/entries"
THUMBS_DIR="$CACHE_DIR/thumbnails"
INDEX_FILE="$CACHE_DIR/index.txt"
LEGACY_FILE="$HOME/.cache/clipboard_history.txt"

mkdir -p "$ENTRIES_DIR" "$THUMBS_DIR" 2>/dev/null || {
    CACHE_DIR="/tmp/clipboard"
    ENTRIES_DIR="$CACHE_DIR/entries"
    THUMBS_DIR="$CACHE_DIR/thumbnails"
    INDEX_FILE="$CACHE_DIR/index.txt"
    LEGACY_FILE="$CACHE_DIR/clipboard_history.txt"
    mkdir -p "$ENTRIES_DIR" "$THUMBS_DIR" 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# Item Resolver
# ------------------------------------------------------------------------------
resolve_and_preview_item() {
    local raw_entry="$1"
    [[ -z "$raw_entry" ]] && return 0

    # 1. Cliphist item format: "<id>\t<content>"
    local re_cliphist='^([0-9]+)[[:space:]]'
    if [[ "$raw_entry" =~ $re_cliphist ]] && command -v cliphist >/dev/null 2>&1; then
        local clip_id="${BASH_REMATCH[1]}"
        local decoded_tmp
        decoded_tmp="$(mktemp --suffix=.dat)"
        cliphist decode "$clip_id" > "$decoded_tmp" 2>/dev/null || true

        if [[ -s "$decoded_tmp" ]]; then
            "$PREVIEWER" --file "$decoded_tmp"
            rm -f "$decoded_tmp"
            return 0
        fi
        rm -f "$decoded_tmp"
    fi

    # 2. Hash in parentheses format: "(<hash>)"
    local re_hash='\(([a-f0-9]{12,64})\)'
    if [[ "$raw_entry" =~ $re_hash ]]; then
        local hash="${BASH_REMATCH[1]}"
        if [[ -f "$ENTRIES_DIR/${hash}.png" ]]; then
            "$PREVIEWER" --image "$ENTRIES_DIR/${hash}.png"
            return 0
        elif [[ -f "$ENTRIES_DIR/${hash}.txt" ]]; then
            "$PREVIEWER" --file "$ENTRIES_DIR/${hash}.txt"
            return 0
        fi
    fi

    # 3. Check if raw entry is a local file
    local cleaned_entry
    cleaned_entry="$(echo "$raw_entry" | sed -e 's/^img:[^:]*:text://' -e 's/^text://' | xargs)"
    if [[ -f "$cleaned_entry" ]]; then
        "$PREVIEWER" --file "$cleaned_entry"
        return 0
    fi

    # 4. Fallback: treat string as text preview
    "$PREVIEWER" --text "$cleaned_entry"
}

copy_entry_to_clipboard() {
    local raw_entry="$1"
    [[ -z "$raw_entry" ]] && return 0

    # Check for cliphist
    local re_cliphist='^([0-9]+)[[:space:]]'
    if [[ "$raw_entry" =~ $re_cliphist ]] && command -v cliphist >/dev/null 2>&1; then
        local clip_id="${BASH_REMATCH[1]}"
        cliphist decode "$clip_id" | wl-copy
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "Clipboard" "Copied to Clipboard" "Item #$clip_id copied" -i edit-paste 2>/dev/null || true
        fi
        return 0
    fi

    # Check for entry hash
    local re_hash='\(([a-f0-9]{12,64})\)'
    if [[ "$raw_entry" =~ $re_hash ]]; then
        local hash="${BASH_REMATCH[1]}"
        if [[ -f "$ENTRIES_DIR/${hash}.png" ]]; then
            wl-copy --type image/png < "$ENTRIES_DIR/${hash}.png"
            if command -v notify-send >/dev/null 2>&1; then
                notify-send -a "Clipboard" "Copied Image to Clipboard" "Image ($hash) restored" -i "$THUMBS_DIR/${hash}.png" 2>/dev/null || true
            fi
            return 0
        elif [[ -f "$ENTRIES_DIR/${hash}.txt" ]]; then
            wl-copy < "$ENTRIES_DIR/${hash}.txt"
            local first_line
            first_line="$(head -n 1 "$ENTRIES_DIR/${hash}.txt" | cut -c 1-60)"
            if command -v notify-send >/dev/null 2>&1; then
                notify-send -a "Clipboard" "Copied to Clipboard" "$first_line" -i edit-paste 2>/dev/null || true
            fi
            return 0
        fi
    fi

    # Fallback to direct text
    local cleaned
    cleaned="$(echo "$raw_entry" | sed -e 's/^img:[^:]*:text://' -e 's/^text://')"
    if command -v wl-copy >/dev/null 2>&1; then
        printf "%s" "$cleaned" | wl-copy
    fi
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Clipboard" "Copied to Clipboard" "$cleaned" -i edit-paste 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# Interactive TUI Browser (fzf + previewer)
# ------------------------------------------------------------------------------
run_interactive_browser() {
    # If not in terminal, spawn small_float terminal emulator
    if [ ! -t 0 ] || [ ! -t 1 ]; then
        if command -v ghostty >/dev/null 2>&1; then
            exec ghostty --class=small_float --title="Clipboard Preview" -e "$SCRIPT_DIR/clipboard-preview.sh" --interactive
        elif command -v ptyxis >/dev/null 2>&1; then
            exec ptyxis --title="Clipboard Preview" -- "$SCRIPT_DIR/clipboard-preview.sh" --interactive
        elif command -v kitty >/dev/null 2>&1; then
            exec kitty --class=small_float --title="Clipboard Preview" "$SCRIPT_DIR/clipboard-preview.sh" --interactive
        fi
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is required for interactive preview mode."
        exit 1
    fi

    # Gather entries: prefer cliphist list if available, else index.txt, else legacy history
    local items=()
    if command -v cliphist >/dev/null 2>&1; then
        mapfile -t items < <(cliphist list 2>/dev/null || true)
    elif [[ -f "$INDEX_FILE" && -s "$INDEX_FILE" ]]; then
        mapfile -t items < <(grep -v '^[[:space:]]*$' "$INDEX_FILE" 2>/dev/null || true)
    elif [[ -f "$LEGACY_FILE" && -s "$LEGACY_FILE" ]]; then
        mapfile -t items < <(grep -v '^[[:space:]]*$' "$LEGACY_FILE" 2>/dev/null || true)
    fi

    if [[ ${#items[@]} -eq 0 ]]; then
        echo "Clipboard history is currently empty."
        read -r -p "Press Enter to exit..."
        exit 0
    fi

    local selected
    selected="$(
        printf "%s\n" "${items[@]}" | fzf --ansi \
            --prompt="Clipboard History > " \
            --header="ENTER: Copy to Clipboard | ESC: Cancel" \
            --preview="$SCRIPT_DIR/clipboard-preview.sh --preview-item {}" \
            --preview-window="right:60%:wrap"
    )"

    if [[ -n "$selected" ]]; then
        copy_entry_to_clipboard "$selected"
    fi
}

# ------------------------------------------------------------------------------
# CLI Router
# ------------------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
    if [ -t 0 ] && [ -t 1 ]; then
        # Running in interactive terminal without args: preview active clipboard
        "$PREVIEWER" --clipboard
    else
        # Running from desktop shortcut without args: interactive TUI browser
        run_interactive_browser
    fi
    exit 0
fi

case "$1" in
    -i|--interactive)
        run_interactive_browser
        ;;
    --preview-item)
        shift
        resolve_and_preview_item "$*"
        ;;
    --copy)
        shift
        copy_entry_to_clipboard "$*"
        ;;
    -h|--help)
        echo "Usage: clipboard-preview.sh [-i|--interactive] [--preview-item <item>] [--copy <item>]"
        ;;
    *)
        resolve_and_preview_item "$*"
        ;;
esac
