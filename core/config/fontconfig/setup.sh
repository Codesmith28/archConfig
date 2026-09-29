#!/usr/bin/env bash
# ==============================================================================
# Fontconfig Setup & Global Override Script
# ==============================================================================
# Configures system-wide (/etc/fonts/local.conf) and user-space (~/.config/fontconfig)
# font preferences and overrides. Uses sudo by default to keep system-wide
# and user-space configs synchronized.
#
# Usage:
#   ./setup.sh          # Synchronizes system-wide & user-space (auto-elevates via sudo)
#   ./setup.sh --user   # User-space only (~/.config/fontconfig, no sudo required)
#   ./setup.sh --system # Explicit system-wide and user-space sync (default)
# ==============================================================================
set -euo pipefail

# 1. Resolve repository directory and target user
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)"
TARGET_HOME="${TARGET_HOME:-$HOME}"
USER_CONFIG_DIR="$TARGET_HOME/.config/fontconfig"
FONTS_CONF="$SCRIPT_DIR/fonts.conf"

# System-wide configuration with sudo is enabled by default
APPLY_SYSTEM=true

# Parse CLI arguments
for arg in "$@"; do
    case "$arg" in
        --user|-u)
            APPLY_SYSTEM=false
            ;;
        --system)
            APPLY_SYSTEM=true
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -u, --user    Apply in user-space only (~/.config/fontconfig, no sudo)"
            echo "  --system      Apply system-wide (/etc/fonts/local.conf) & user-space (default)"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--user | --system | -h]"
            exit 1
            ;;
    esac
done

# If system-wide is enabled and not running as root, escalate via sudo
if [ "$APPLY_SYSTEM" = true ] && [ "$EUID" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        exec sudo "$SCRIPT_DIR/setup.sh" "$@"
    else
        echo "==> [WARN] 'sudo' not available; proceeding with user-space configuration only."
        APPLY_SYSTEM=false
    fi
fi

echo "=================================================="
echo "  Fontconfig Setup & Verification"
echo "=================================================="
echo "  Target User : $TARGET_USER"
echo "  Config Path : $FONTS_CONF"
echo "  Scope       : $([ "$APPLY_SYSTEM" = true ] && echo "System-Wide & User-Space" || echo "User-Space Only")"
echo "=================================================="

# 2. System-wide configuration (/etc/fonts/local.conf)
if [ "$APPLY_SYSTEM" = true ]; then
    echo ""
    echo "==> [1/3] Installing system-wide configuration (/etc/fonts/local.conf)..."
    mkdir -p /etc/fonts
    cp "$FONTS_CONF" /etc/fonts/local.conf
    chmod 644 /etc/fonts/local.conf
    echo "    ✓ System-level configuration installed to /etc/fonts/local.conf"

    echo ""
    echo "==> [2/3] Ensuring user-level fontconfig symlink..."
else
    echo ""
    echo "==> [1/2] Ensuring user-level fontconfig symlink..."
fi

# 3. User-level configuration (~/.config/fontconfig)
mkdir -p "$TARGET_HOME/.config" "$TARGET_HOME/.local/share/fonts"

if [ -L "$USER_CONFIG_DIR" ]; then
    CURRENT_TARGET="$(readlink -f "$USER_CONFIG_DIR" 2>/dev/null || true)"
    if [ "$CURRENT_TARGET" = "$SCRIPT_DIR" ]; then
        echo "    ✓ Symlink verified: $USER_CONFIG_DIR -> $SCRIPT_DIR"
    else
        echo "    Updating symlink: $USER_CONFIG_DIR -> $SCRIPT_DIR"
        ln -sfn "$SCRIPT_DIR" "$USER_CONFIG_DIR"
    fi
elif [ -d "$USER_CONFIG_DIR" ]; then
    BACKUP_PATH="${USER_CONFIG_DIR}.bak_$(date +%s)"
    echo "    Backing up existing directory $USER_CONFIG_DIR -> $BACKUP_PATH"
    mv "$USER_CONFIG_DIR" "$BACKUP_PATH"
    ln -s "$SCRIPT_DIR" "$USER_CONFIG_DIR"
    echo "    ✓ Created symlink: $USER_CONFIG_DIR -> $SCRIPT_DIR"
else
    ln -s "$SCRIPT_DIR" "$USER_CONFIG_DIR"
    echo "    ✓ Created symlink: $USER_CONFIG_DIR -> $SCRIPT_DIR"
fi

if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    chown -h "$TARGET_USER:" "$USER_CONFIG_DIR" 2>/dev/null || true
    chown -R "$TARGET_USER:" "$TARGET_HOME/.local/share/fonts" 2>/dev/null || true
fi

# 4. Refresh font caches
if [ "$APPLY_SYSTEM" = true ]; then
    echo ""
    echo "==> [3/3] Refreshing font caches..."
else
    echo ""
    echo "==> [2/2] Refreshing font caches..."
fi

if [ "$EUID" -eq 0 ]; then
    fc-cache -f 2>/dev/null || true
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$TARGET_USER" fc-cache -f 2>/dev/null || true
    fi
else
    fc-cache -f 2>/dev/null || true
fi
echo "    ✓ Font caches updated."

# 5. Font resolution verification
match_font() {
    local query="$1"
    if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$TARGET_USER" fc-match "$query"
    else
        fc-match "$query"
    fi
}

echo ""
echo "==> Verifying font resolutions:"
echo "    --- Browser Default Overrides ---"
declare -a test_mono_fonts=(
    "monospace"
    "Liberation Mono"
    "Courier"
    "Courier New"
    "TeX Gyre Cursor"
)
all_mono_ok=true
for t in "${test_mono_fonts[@]}"; do
    res="$(match_font "$t")"
    printf "    %-20s -> %s\n" "$t" "$res"
    if [[ ! "$res" =~ JetBrainsMono ]]; then
        all_mono_ok=false
    fi
done

echo ""
echo "    --- System Default Families ---"
declare -a test_generic_fonts=(
    "sans-serif"
    "sans"
    "system-ui"
    "serif"
)
for t in "${test_generic_fonts[@]}"; do
    res="$(match_font "$t")"
    printf "    %-20s -> %s\n" "$t" "$res"
done

echo ""
if [ "$all_mono_ok" = true ]; then
    echo "✨ Configuration complete! Monospace queries resolve to JetBrainsMono Nerd Font."
else
    echo "⚠️  Note: Some monospace queries resolved to fallback fonts. Check installed fonts in ~/.local/share/fonts."
fi
