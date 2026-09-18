#!/usr/bin/env bash
# ==============================================================================
# Fontconfig Setup & Dynamic Monospace Override Script (Always System-Wide)
# ==============================================================================
# Automatically detects the CURRENT set monospace font (from fonts.conf or
# GNOME settings) and overrides ALL other monospace fonts on the system
# (including Ubuntu Mono itself, DejaVu Sans Mono, Liberation Mono, etc.)
# so that any monospace request resolves to that chosen font.
#
# Configures both system-wide (/etc/fonts/) and user-space (~/.config/fontconfig).
#
# Usage:
#   ./setup.sh               # Uses current set monospace font (from fonts.conf)
#   ./setup.sh --font "..."  # Set a new monospace font and override everything with it
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
REAL_HOME="${REAL_HOME:-$HOME}"
USER_CONFIG_DIR="$REAL_HOME/.config/fontconfig"
OVERRIDE_CONF="$SCRIPT_DIR/conf.d/10-override-monospace.conf"
SANS_OVERRIDE_CONF="$SCRIPT_DIR/conf.d/10-override-sans-serif.conf"
FONTS_CONF="$SCRIPT_DIR/fonts.conf"

CLI_FONT=""

# ------------------------------------------------------------------------------
# Helper: Detect currently set monospace font
# ------------------------------------------------------------------------------
get_current_monospace_font() {
    local font=""

    # 1. Try reading from fonts.conf in this directory
    if [[ -f "$FONTS_CONF" ]]; then
        font=$(python3 -c "
import xml.etree.ElementTree as ET
try:
    tree = ET.parse('$FONTS_CONF')
    for alias in tree.getroot().findall('alias'):
        fam = alias.find('family')
        if fam is not None and fam.text.strip() == 'monospace':
            prefer = alias.find('prefer')
            if prefer is not None:
                p = prefer.find('family')
                if p is not None and p.text.strip():
                    print(p.text.strip())
                    break
except Exception:
    pass
" 2>/dev/null)
    fi

    # 2. Fallback to GNOME interface monospace-font-name
    if [[ -z "$font" ]] && command -v gsettings >/dev/null 2>&1; then
        local gnome_font
        gnome_font=$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null | tr -d "'\"")
        font=$(echo "$gnome_font" | sed -E 's/[[:space:]]+[0-9]+([.][0-9]+)?$//')
    fi

    # 3. Fallback to system fc-match
    if [[ -z "$font" ]]; then
        font=$(fc-match monospace -f "%{family}\n" 2>/dev/null | cut -d',' -f1)
    fi

    echo "$font"
}

# ------------------------------------------------------------------------------
# Helper: Update fonts.conf default monospace
# ------------------------------------------------------------------------------
update_fonts_conf() {
    local new_font="$1"
    cat <<EOF >"$FONTS_CONF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>$new_font</family>
    </prefer>
  </alias>
</fontconfig>
EOF
    echo "    ✓ Updated fonts.conf default monospace to '$new_font'"
}

# ------------------------------------------------------------------------------
# Parse CLI arguments
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
    --font | -f)
        CLI_FONT="$2"
        shift 2
        ;;
    --help | -h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -f, --font FONT  Set and use a specific monospace font (updates fonts.conf)"
        echo "  -h, --help       Show this help message"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Run '$0 --help' for usage."
        exit 1
        ;;
    esac
done

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
echo "  Fontconfig Setup & Monospace Override (System-Wide)"
echo "=================================================="

# Determine active target monospace font
if [[ -n "$CLI_FONT" ]]; then
    TARGET_MONO="$CLI_FONT"
    update_fonts_conf "$TARGET_MONO"
    FONT_SOURCE="CLI argument (--font)"
else
    TARGET_MONO="$(get_current_monospace_font)"
    if [[ -z "$TARGET_MONO" ]]; then
        TARGET_MONO="UbuntuSansMono Nerd Font"
        update_fonts_conf "$TARGET_MONO"
        FONT_SOURCE="Default fallback"
    else
        FONT_SOURCE="fonts.conf"
    fi
fi

echo "  Target Monospace Font: '$TARGET_MONO'"
echo "  Source               : $FONT_SOURCE"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. Monospace & Sans-Serif override rules (redirect explicit requests)
# ------------------------------------------------------------------------------
echo ""
echo "==> [1/4] Configuring monospace and sans-serif overrides..."
mkdir -p "$SCRIPT_DIR/conf.d"

declare -a override_families=(
    "Courier"
    "Courier New"
    "Consolas"
    "Menlo"
    "Monaco"
    "DejaVu Sans Mono"
    "Liberation Mono"
    "LiberationMono"
    "Ubuntu Mono"
)

cat <<EOF >"$OVERRIDE_CONF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <!-- ===================================================================== -->
  <!-- Redirect explicit monospace font requests to generic 'monospace'.     -->
  <!-- The preferred font is defined centrally in fonts.conf.                -->
  <!-- ===================================================================== -->
EOF

for fam in "${override_families[@]}"; do
    cat <<EOF >>"$OVERRIDE_CONF"
  <match target="pattern">
    <test name="family" qual="any">
      <string>$fam</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>monospace</string>
    </edit>
  </match>
EOF
done

echo "</fontconfig>" >>"$OVERRIDE_CONF"
echo "    ✓ Generated $(basename "$OVERRIDE_CONF") (redirecting to 'monospace')"

declare -a override_sans_families=(
    "Arial"
    "Helvetica"
    "Helvetica Neue"
    "Liberation Sans"
    "LiberationSans"
    "Arimo"
    "DejaVu Sans"
    "Noto Sans"
    "Roboto"
    "Open Sans"
    "Segoe UI"
    "Cantarell"
    "Ubuntu"
    "TeX Gyre Heros"
    "Nimbus Sans"
    "Nimbus Sans L"
)

cat <<EOF >"$SANS_OVERRIDE_CONF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <!-- ===================================================================== -->
  <!-- Redirect explicit sans-serif font requests to generic 'sans-serif'.   -->
  <!-- The preferred font is defined in conf.d/49-default-sans-serif.conf.   -->
  <!-- ===================================================================== -->
EOF

for fam in "${override_sans_families[@]}"; do
    cat <<EOF >>"$SANS_OVERRIDE_CONF"
  <match target="pattern">
    <test name="family" qual="any">
      <string>$fam</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>sans-serif</string>
    </edit>
  </match>
EOF
done

echo "</fontconfig>" >>"$SANS_OVERRIDE_CONF"
echo "    ✓ Generated $(basename "$SANS_OVERRIDE_CONF") (redirecting to 'sans-serif')"

# ------------------------------------------------------------------------------
# 2. System-wide configuration (/etc/fonts/)
# ------------------------------------------------------------------------------
echo ""
echo "==> [2/4] Applying system-wide configuration (/etc/fonts/)..."
$SUDO mkdir -p /etc/fonts/conf.d

# Install local.conf
if [ -f "$FONTS_CONF" ]; then
    echo "    Installing /etc/fonts/local.conf..."
    $SUDO cp "$FONTS_CONF" /etc/fonts/local.conf
    $SUDO chmod 644 /etc/fonts/local.conf
fi

# Install all conf.d rules
if [ -d "$SCRIPT_DIR/conf.d" ]; then
    for conf_file in "$SCRIPT_DIR/conf.d"/*.conf; do
        if [ -f "$conf_file" ]; then
            filename="$(basename "$conf_file")"
            echo "    Installing /etc/fonts/conf.d/$filename..."
            $SUDO cp "$conf_file" "/etc/fonts/conf.d/$filename"
            $SUDO chmod 644 "/etc/fonts/conf.d/$filename"
        fi
    done
fi
echo "    ✓ System-level configuration installed."

# ------------------------------------------------------------------------------
# 3. User-level configuration (~/.config/fontconfig)
# ------------------------------------------------------------------------------
echo ""
echo "==> [3/4] Ensuring user-level fontconfig symlink..."
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
# 4. Refresh system and user font caches
# ------------------------------------------------------------------------------
echo ""
echo "==> [4/4] Refreshing font caches..."
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
echo "    --- Sans-Serif Overrides ---"
declare -a test_sans_fonts=(
    "sans-serif"
    "sans"
    "system-ui"
    "Arial"
    "Helvetica"
    "Roboto"
    "Liberation Sans"
    "Arimo"
    "DejaVu Sans"
    "Noto Sans"
)

for t in "${test_sans_fonts[@]}"; do
    printf "    %-20s -> %s\n" "$t" "$(fc-match "$t")"
done

echo ""
echo "✨ System-wide configuration complete!"
echo "   All monospace queries resolve to '$TARGET_MONO'."
echo "   All sans-serif queries resolve to '$(fc-match sans-serif -f "%{family}\n" | cut -d',' -f1)'."
