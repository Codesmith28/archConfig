#!/usr/bin/env bash
# ==============================================================================
# Extensible Multi-Format Content Previewer
# ==============================================================================
# Handles visual and terminal previewing for files, images, code/text, directories,
# and clipboard contents.
#
# Supports:
# - Images: chafa / yazi / python-PIL ANSI truecolor renderer fallback
# - Text & Code: bat (with syntax highlighting and line numbers) / cat fallback
# - Directories: eza / tree / ls
# - Archives & Binaries: file identification, mediainfo/ffprobe, hex dump
# - Wayland Clipboard: image or multi-line text detection and preview
# ==============================================================================
set -euo pipefail

WIDTH="${PREVIEW_WIDTH:-$(tput cols 2>/dev/null || echo 80)}"
HEIGHT="${PREVIEW_HEIGHT:-$(tput lines 2>/dev/null || echo 25)}"
MAX_LINES="${PREVIEW_MAX_LINES:-300}"

# ------------------------------------------------------------------------------
# Helpers & Renderers
# ------------------------------------------------------------------------------
render_image_ansi() {
    local img_path="$1"
    local max_w="${2:-$WIDTH}"
    local max_h="${3:-$HEIGHT}"

    python3 - "$img_path" "$max_w" "$max_h" << 'EOF' 2>/dev/null || true
import sys, os
from PIL import Image

path = sys.argv[1]
try:
    max_w = max(20, int(sys.argv[2]))
    max_h = max(10, int(sys.argv[3]))
except Exception:
    max_w, max_h = 80, 25

if not os.path.isfile(path):
    sys.exit(1)

try:
    with Image.open(path) as raw:
        w, h = raw.size
        fmt = raw.format or "UNKNOWN"
        mode = raw.mode
        im = raw.convert("RGB")

    # Header with metadata
    file_size = os.path.getsize(path)
    if file_size >= 1024 * 1024:
        size_str = f"{file_size / (1024 * 1024):.2f} MB"
    else:
        size_str = f"{file_size / 1024:.1f} KB"
    print(f"\033[1;36m[Image: {fmt} | {w}x{h} px | {mode} | {size_str}]\033[0m")

    # 2 vertical pixels per terminal line using '▀'
    # Aspect ratio correction (character cells are ~2x taller than wide)
    aspect = (w / max(1, h)) * 0.5
    target_w = min(max_w, w)
    target_h = int(target_w / max(0.01, aspect))

    # Cap to max terminal height (each row is 2 vertical pixels)
    available_rows = max(4, max_h - 3)
    if target_h > available_rows * 2:
        target_h = available_rows * 2
        target_w = max(4, int(target_h * aspect))

    if target_h % 2 != 0:
        target_h += 1

    im = im.resize((max(1, target_w), max(1, target_h)), Image.Resampling.BILINEAR)
    px = im.load()

    out = []
    for y in range(0, target_h, 2):
        row = []
        for x in range(target_w):
            r1, g1, b1 = px[x, y]
            r2, g2, b2 = px[x, y + 1] if (y + 1 < target_h) else (0, 0, 0)
            row.append(f"\033[38;2;{r1};{g1};{b1}m\033[48;2;{r2};{g2};{b2}m▀\033[0m")
        out.append("".join(row))
    print("\n".join(out))
except Exception as err:
    print(f"Image preview error: {err}", file=sys.stderr)
EOF
}

preview_image() {
    local target="$1"
    [[ -f "$target" ]] || { echo "File not found: $target"; return 1; }

    # Priority 1: chafa (symbols/sixel/kitty high-performance previewer)
    if command -v chafa >/dev/null 2>&1; then
        chafa --format=symbols --size="${WIDTH}x$((HEIGHT - 2))" "$target" 2>/dev/null || true
        return 0
    fi

    # Priority 2: Python PIL ANSI Truecolor half-block renderer
    if command -v python3 >/dev/null 2>&1; then
        render_image_ansi "$target" "$WIDTH" "$HEIGHT"
        return 0
    fi

    # Priority 3: ImageMagick identify / metadata summary
    if command -v magick >/dev/null 2>&1; then
        magick identify "$target"
    elif command -v identify >/dev/null 2>&1; then
        identify "$target"
    else
        file -b "$target"
    fi
}

preview_text() {
    local target="$1"
    local is_file="${2:-true}"

    if [[ "$is_file" == "true" ]]; then
        [[ -f "$target" ]] || { echo "File not found: $target"; return 1; }
        if command -v bat >/dev/null 2>&1; then
            bat --color=always --style=numbers,changes \
                --terminal-width="$WIDTH" \
                --line-range ":$MAX_LINES" "$target" 2>/dev/null || cat -n "$target" | head -n "$MAX_LINES"
        else
            cat -n "$target" | head -n "$MAX_LINES"
        fi
    else
        # Direct string input
        if command -v bat >/dev/null 2>&1; then
            printf "%s" "$target" | bat --color=always --style=numbers,changes \
                --terminal-width="$WIDTH" \
                --line-range ":$MAX_LINES" 2>/dev/null || printf "%s" "$target" | cat -n | head -n "$MAX_LINES"
        else
            printf "%s" "$target" | cat -n | head -n "$MAX_LINES"
        fi
    fi
}

preview_directory() {
    local dir="$1"
    [[ -d "$dir" ]] || { echo "Directory not found: $dir"; return 1; }

    echo -e "\033[1;34m[Directory: $dir]\033[0m"
    if command -v eza >/dev/null 2>&1; then
        eza --tree --level=2 --icons --color=always "$dir" 2>/dev/null | head -n "$MAX_LINES" || ls -la "$dir"
    elif command -v tree >/dev/null 2>&1; then
        tree -C -L 2 "$dir" 2>/dev/null | head -n "$MAX_LINES" || ls -la "$dir"
    else
        ls -la "$dir" | head -n "$MAX_LINES"
    fi
}

preview_binary() {
    local file="$1"
    echo -e "\033[1;33m[Binary / Data: $(basename "$file")]\033[0m"
    file -b "$file" || true
    echo ""
    if command -v xxd >/dev/null 2>&1; then
        xxd -l 256 "$file" 2>/dev/null || true
    elif command -v hexdump >/dev/null 2>&1; then
        hexdump -C -n 256 "$file" 2>/dev/null || true
    fi
}

preview_clipboard() {
    if ! command -v wl-paste >/dev/null 2>&1; then
        echo "wl-paste not available to inspect clipboard"
        return 1
    fi

    local types
    types="$(wl-paste --list-types 2>/dev/null || true)"

    if echo "$types" | grep -qE "^image/(png|jpeg|webp|bmp)"; then
        local tmp_img
        tmp_img="$(mktemp --suffix=.png)"
        wl-paste > "$tmp_img" 2>/dev/null || true
        preview_image "$tmp_img"
        rm -f "$tmp_img"
    elif [[ -n "$types" ]]; then
        local content
        content="$(wl-paste 2>/dev/null || true)"
        preview_text "$content" false
    else
        echo "Clipboard is currently empty."
    fi
}

# ------------------------------------------------------------------------------
# Dispatcher
# ------------------------------------------------------------------------------
show_help() {
    cat << 'EOF'
Usage: previewer.sh [OPTIONS] [TARGET]

Options:
  --file <path>         Preview a file (code, text, image, directory)
  --image <path>        Force image preview handler
  --text <string>       Preview text string directly
  --clipboard           Preview current Wayland clipboard content
  --width <cols>        Override preview width in columns
  --height <lines>      Override preview height in rows
  --max-lines <n>       Maximum lines to display for text (default: 300)
  -h, --help            Show this help message

If no option is specified and TARGET is passed, type is detected automatically.
If no arguments are provided, reads from standard input.
EOF
}

TARGET=""
MODE="auto"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --file)
            TARGET="$2"
            MODE="file"
            shift 2
            ;;
        --image)
            TARGET="$2"
            MODE="image"
            shift 2
            ;;
        --text)
            TARGET="$2"
            MODE="text"
            shift 2
            ;;
        --clipboard)
            MODE="clipboard"
            shift
            ;;
        --width)
            WIDTH="$2"
            shift 2
            ;;
        --height)
            HEIGHT="$2"
            shift 2
            ;;
        --max-lines)
            MAX_LINES="$2"
            shift 2
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

if [[ "$MODE" == "clipboard" ]]; then
    preview_clipboard
    exit 0
fi

if [[ "$MODE" == "text" ]]; then
    preview_text "$TARGET" false
    exit 0
fi

if [[ "$MODE" == "image" ]]; then
    preview_image "$TARGET"
    exit 0
fi

# Handle STDIN if no target is given
if [[ -z "$TARGET" ]]; then
    if [ ! -t 0 ]; then
        input="$(cat)"
        preview_text "$input" false
        exit 0
    else
        show_help
        exit 1
    fi
fi

# Auto-detect target type
if [[ -d "$TARGET" ]]; then
    preview_directory "$TARGET"
    exit 0
fi

if [[ -f "$TARGET" ]]; then
    mime_type="$(file -b --mime-type "$TARGET" 2>/dev/null || true)"
    case "$mime_type" in
        image/*)
            preview_image "$TARGET"
            ;;
        text/*|application/json|application/xml|application/javascript|application/x-sh|application/x-shellscript)
            preview_text "$TARGET" true
            ;;
        *)
            # Check by extension for common image formats
            case "${TARGET,,}" in
                *.png|*.jpg|*.jpeg|*.webp|*.gif|*.bmp|*.svg|*.avif|*.jxl)
                    preview_image "$TARGET"
                    ;;
                *)
                    # Binary or unrecognized
                    preview_binary "$TARGET"
                    ;;
            esac
            ;;
    esac
    exit 0
fi

# Fallback: treat as raw text
preview_text "$TARGET" false
