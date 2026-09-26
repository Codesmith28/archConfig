#!/usr/bin/env bash
# ==============================================================================
# Fontconfig Setup & Global Override Script (System-Wide & User-Space)
# ==============================================================================
# Configures system-wide (/etc/fonts/local.conf) and user-space (~/.config/fontconfig)
# font preferences and overrides using a single consolidated fonts.conf file.
#
# Usage:
#   ./setup.sh                       # Applies current configuration
#   ./setup.sh -f "Font Name"        # Set monospace font and re-apply
#   ./setup.sh -s "Font Name"        # Set sans/serif font and re-apply
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
REAL_HOME="${REAL_HOME:-$HOME}"
USER_CONFIG_DIR="$REAL_HOME/.config/fontconfig"
FONTS_CONF="$SCRIPT_DIR/fonts.conf"

CLI_MONO=""
CLI_SANS=""
CLI_SERIF=""

# ------------------------------------------------------------------------------
# Helpers: Read / update font preferences in fonts.conf
# ------------------------------------------------------------------------------
get_font_pref() {
    local family="$1"
    python3 -c "
import xml.etree.ElementTree as ET
try:
    tree = ET.parse('$FONTS_CONF')
    for alias in tree.getroot().findall('alias'):
        fam = alias.find('family')
        if fam is not None and fam.text.strip() == '$family':
            prefer = alias.find('prefer')
            if prefer is not None:
                p = prefer.find('family')
                if p is not None and p.text.strip():
                    print(p.text.strip())
                    break
except Exception:
    pass
" 2>/dev/null
}

update_font_pref() {
    local family="$1"
    local new_font="$2"
    python3 -c "
import re
with open('$FONTS_CONF', 'r') as f:
    content = f.read()
pattern = rf'(<alias>\s*<family>{re.escape(\"$family\")}</family>\s*<prefer>\s*<family>)[^<]*(</family>)'
content = re.sub(pattern, rf'\g<1>{new_font}\2', content)
if '$family' == 'monospace':
    courier_pattern = r'(<match target=\"pattern\"><test name=\"family\" qual=\"any\"><string>(?:Courier|TeX Gyre Cursor)<\/string><\/test><edit name=\"family\" mode=\"prepend_first\" binding=\"strong\"><string>)[^<]*(<\/string><\/edit><\/match>)'
    content = re.sub(courier_pattern, rf'\g<1>{new_font}\2', content)
with open('$FONTS_CONF', 'w') as f:
    f.write(content)
"
    echo "    ✓ Updated fonts.conf default $family to '$new_font'"
}

# ------------------------------------------------------------------------------
# Parse CLI arguments
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
    --font | -f | --mono | -m)
        CLI_MONO="$2"
        shift 2
        ;;
    --sans | -s)
        CLI_SANS="$2"
        shift 2
        ;;
    --serif | -r)
        CLI_SERIF="$2"
        shift 2
        ;;
    --help | -h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -f, --font FONT   Set monospace font in fonts.conf"
        echo "  -s, --sans FONT   Set sans-serif font in fonts.conf"
        echo "  -r, --serif FONT  Set serif font in fonts.conf"
        echo "  -h, --help        Show this help message"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Run '$0 --help' for usage."
        exit 1
        ;;
    esac
done

# Apply CLI updates if requested
if [[ -n "$CLI_MONO" ]]; then
    update_font_pref "monospace" "$CLI_MONO"
fi
if [[ -n "$CLI_SANS" ]]; then
    update_font_pref "sans-serif" "$CLI_SANS"
    update_font_pref "sans" "$CLI_SANS"
    update_font_pref "system-ui" "$CLI_SANS"
fi
if [[ -n "$CLI_SERIF" ]]; then
    update_font_pref "serif" "$CLI_SERIF"
fi

TARGET_MONO="$(get_font_pref 'monospace')"
TARGET_SANS="$(get_font_pref 'sans-serif')"
TARGET_SERIF="$(get_font_pref 'serif')"

# ------------------------------------------------------------------------------
# Ensure Sudo / Root Privileges
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    echo "==> Requesting sudo privileges to configure system-wide (/etc/fonts/)..."
    sudo -v
    SUDO="sudo"
else
    SUDO=""
fi

echo "=================================================="
echo "  Fontconfig Setup & Global Overrides"
echo "=================================================="
echo "  Monospace Target : '$TARGET_MONO'"
echo "  Sans-Serif Target: '$TARGET_SANS'"
echo "  Serif Target     : '$TARGET_SERIF'"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. System-wide configuration (/etc/fonts/local.conf)
# ------------------------------------------------------------------------------
echo ""
echo "==> [1/3] Installing system-wide configuration (/etc/fonts/local.conf)..."
$SUDO mkdir -p /etc/fonts
$SUDO cp "$FONTS_CONF" /etc/fonts/local.conf
$SUDO chmod 644 /etc/fonts/local.conf

# Clean up legacy split files from previous configurations if present
$SUDO rm -f /etc/fonts/conf.d/10-override-*.conf /etc/fonts/conf.d/49-default-*.conf 2>/dev/null || true
echo "    ✓ System-level configuration installed to /etc/fonts/local.conf"

# ------------------------------------------------------------------------------
# 2. User-level configuration (~/.config/fontconfig)
# ------------------------------------------------------------------------------
echo ""
echo "==> [2/3] Ensuring user-level fontconfig symlink..."
mkdir -p "$REAL_HOME/.config"

if [ -L "$USER_CONFIG_DIR" ]; then
    CURRENT_TARGET="$(readlink -f "$USER_CONFIG_DIR")"
    if [ "$CURRENT_TARGET" = "$SCRIPT_DIR" ]; then
        echo "    ✓ Symlink verified: $USER_CONFIG_DIR -> $SCRIPT_DIR"
    else
        echo "    Updating symlink: $USER_CONFIG_DIR -> $SCRIPT_DIR"
        ln -sfn "$SCRIPT_DIR" "$USER_CONFIG_DIR"
    fi
elif [ -d "$USER_CONFIG_DIR" ]; then
    echo "    Backing up existing directory $USER_CONFIG_DIR -> ${USER_CONFIG_DIR}.bak"
    mv "$USER_CONFIG_DIR" "${USER_CONFIG_DIR}.bak"
    ln -s "$SCRIPT_DIR" "$USER_CONFIG_DIR"
    echo "    ✓ Created symlink: $USER_CONFIG_DIR -> $SCRIPT_DIR"
else
    ln -s "$SCRIPT_DIR" "$USER_CONFIG_DIR"
    echo "    ✓ Created symlink: $USER_CONFIG_DIR -> $SCRIPT_DIR"
fi

# ------------------------------------------------------------------------------
# 3. Refresh font caches
# ------------------------------------------------------------------------------
echo ""
echo "==> [3/3] Refreshing font caches..."
$SUDO fc-cache -fv
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    su - "$SUDO_USER" -c "fc-cache -f" 2>/dev/null || true
else
    fc-cache -f 2>/dev/null || true
fi
echo "    ✓ Font caches updated."

# ------------------------------------------------------------------------------
# Verification
# ------------------------------------------------------------------------------
echo ""
echo "==> Verifying font resolutions:"
echo "    --- Monospace Overrides ---"
declare -a test_mono_fonts=(
    "monospace"
    "Ubuntu Mono"
    "Liberation Mono"
    "DejaVu Sans Mono"
    "Courier"
    "Menlo"
)
for t in "${test_mono_fonts[@]}"; do
    printf "    %-20s -> %s\n" "$t" "$(fc-match "$t")"
done

echo ""
echo "    --- Sans-Serif Resolutions ---"
declare -a test_sans_fonts=(
    "sans-serif"
    "sans"
    "system-ui"
    "Arial"
    "Helvetica"
    "Roboto"
    "Liberation Sans"
    "Noto Sans"
)
for t in "${test_sans_fonts[@]}"; do
    printf "    %-20s -> %s\n" "$t" "$(fc-match "$t")"
done

echo ""
echo "    --- Serif Resolutions ---"
declare -a test_serif_fonts=(
    "serif"
    "Times New Roman"
    "Times"
    "Georgia"
    "Liberation Serif"
    "Noto Serif"
    "DejaVu Serif"
)
for t in "${test_serif_fonts[@]}"; do
    printf "    %-20s -> %s\n" "$t" "$(fc-match "$t")"
done

echo ""
echo "✨ Configuration complete!"
echo "   Monospace queries (including legacy overrides) resolve to '$TARGET_MONO'."
echo "   Default sans-serif queries resolve to '$TARGET_SANS'."
echo "   Default serif queries resolve to '$TARGET_SERIF'."
