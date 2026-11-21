#!/usr/bin/env bash
# ==============================================================================
# Waybar, Borders & Launcher Theme Switcher (Multi-Theme Controller)
# Touches strictly 3 areas and nothing else:
#   1. Waybar (theme.css palette & hot-reload)
#   2. Hyprland Borders (active & inactive border colors live + persistent)
#   3. Launcher (Wofi CSS palette & Hyprlauncher hyprtoolkit.conf)
# Never touches GTK, GNOME, GSettings, or system-wide application theming.
# Supported Themes:
#   Dark:  catppuccin, tokyo-night, monochrome
#   Light: catppuccin-latte, tokyo-night-light, monochrome-light
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_WAYBAR_DIR="$(cd "$SCRIPT_DIR/../../waybar" 2>/dev/null && pwd || true)"
USER_WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
REPO_WOFI_DIR="$(cd "$SCRIPT_DIR/../../wofi" 2>/dev/null && pwd || true)"
USER_WOFI_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wofi"

STATE_FILE="$HOME/.cache/waybar_theme_state"
HYPR_STATE_FILE="$HOME/.cache/hyprland_theme_state"
mkdir -p "$HOME/.cache"

# Allowed themes (3 dark, 3 light)
ALLOWED_THEMES=(
    "catppuccin"
    "tokyo-night"
    "monochrome"
    "catppuccin-latte"
    "tokyo-night-light"
    "monochrome-light"
)

is_valid_theme() {
    local t="$1"
    for valid in "${ALLOWED_THEMES[@]}"; do
        if [[ "$t" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

normalize_theme() {
    local t="$1"
    case "$t" in
        catpuccin|catppuccin-mocha)
            echo "catppuccin"
            ;;
        catpuccin-latte|latte)
            echo "catppuccin-latte"
            ;;
        tokyonight|tokyonigth|tokyo-night-dark)
            echo "tokyo-night"
            ;;
        tokyonight-light|tokyoknigt-light|tokyo-night-day|day)
            echo "tokyo-night-light"
            ;;
        monochrome-dark)
            echo "monochrome"
            ;;
        monochrome-white|mono-light)
            echo "monochrome-light"
            ;;
        *)
            echo "$t"
            ;;
    esac
}

get_current_theme() {
    local current=""
    if [[ -f "$STATE_FILE" ]]; then
        current="$(head -n 1 "$STATE_FILE" | tr -d '[:space:]')"
    fi
    if [[ -z "$current" && -f "$HYPR_STATE_FILE" ]]; then
        current="$(head -n 1 "$HYPR_STATE_FILE" | tr -d '[:space:]')"
    fi
    current="$(normalize_theme "$current")"
    if ! is_valid_theme "$current"; then
        current="catppuccin"
    fi
    echo "$current"
}

get_next_theme() {
    local current="$1"
    case "$current" in
        catppuccin)        echo "tokyo-night" ;;
        tokyo-night)       echo "monochrome" ;;
        monochrome)        echo "catppuccin-latte" ;;
        catppuccin-latte)  echo "tokyo-night-light" ;;
        tokyo-night-light) echo "monochrome-light" ;;
        monochrome-light)  echo "catppuccin" ;;
        *)                 echo "catppuccin" ;;
    esac
}

show_usage() {
    echo "Usage: $(basename "$0") [OPTIONS] [THEME]"
    echo ""
    echo "Controls Waybar, Hyprland borders, and Launcher styling."
    echo "Supported themes:"
    echo "  Dark:  catppuccin, tokyo-night, monochrome"
    echo "  Light: catppuccin-latte, tokyo-night-light, monochrome-light"
    echo ""
    echo "Options:"
    echo "  -n, --next, --cycle, --toggle  Cycle to the next theme (default if no argument)"
    echo "  -s, --set <THEME>              Select a specific theme"
    echo "  -c, --current                  Print the active theme and exit"
    echo "  -l, --list                     List all supported themes and exit"
    echo "  -m, --menu                     Interactive graphical selector menu"
    echo "  -h, --help                     Display this help message and exit"
}

TARGET_THEME=""

# Parse command line options
if [[ $# -eq 0 ]]; then
    CURRENT="$(get_current_theme)"
    TARGET_THEME="$(get_next_theme "$CURRENT")"
else
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -l|--list)
            for t in "${ALLOWED_THEMES[@]}"; do
                echo "$t"
            done
            exit 0
            ;;
        -c|--current)
            get_current_theme
            exit 0
            ;;
        -n|--next|--cycle|--toggle)
            CURRENT="$(get_current_theme)"
            TARGET_THEME="$(get_next_theme "$CURRENT")"
            ;;
        -m|--menu|menu)
            if [[ -f "$SCRIPT_DIR/launcher-guard.sh" ]]; then
                source "$SCRIPT_DIR/launcher-guard.sh"
                guard_launcher "theme"
            fi
            CHOSEN=""
            OPTIONS="🌸 Catppuccin (Dark)\n🌃 Tokyo Night (Dark)\n◽ Monochrome (Dark)\n☕ Catppuccin Latte (Light)\n☀️ Tokyo Night Light (Light)\n▫️ Monochrome Light (Light)"
            if command -v wofi >/dev/null 2>&1; then
                WOFI_CONF=""
                WOFI_STYLE=""
                if [[ -f "$HOME/.config/wofi/config" && -f "$HOME/.config/wofi/style.css" ]]; then
                    WOFI_CONF="$HOME/.config/wofi/config"
                    WOFI_STYLE="$HOME/.config/wofi/style.css"
                elif [[ -n "$REPO_WOFI_DIR" && -f "$REPO_WOFI_DIR/config" && -f "$REPO_WOFI_DIR/style.css" ]]; then
                    WOFI_CONF="$REPO_WOFI_DIR/config"
                    WOFI_STYLE="$REPO_WOFI_DIR/style.css"
                fi
                WOFI_ARGS=("--dmenu" "--prompt=Select Theme..." "-W" "340" "-L" "6" "-i" "--hide-scroll")
                if [[ -n "$WOFI_CONF" ]]; then WOFI_ARGS+=("--conf" "$WOFI_CONF"); fi
                if [[ -n "$WOFI_STYLE" ]]; then WOFI_ARGS+=("--style" "$WOFI_STYLE"); fi
                CHOSEN="$(echo -e "$OPTIONS" | wofi "${WOFI_ARGS[@]}" 2>/dev/null || true)"
            elif command -v hyprlauncher >/dev/null 2>&1; then
                CHOSEN="$(echo -e "$OPTIONS" | hyprlauncher -m 2>/dev/null || true)"
            elif command -v rofi >/dev/null 2>&1; then
                CHOSEN="$(echo -e "$OPTIONS" | rofi -dmenu -p "Select Theme" 2>/dev/null || true)"
            elif [ -t 0 ] && command -v fzf >/dev/null 2>&1; then
                CHOSEN="$(echo -e "$OPTIONS" | fzf --prompt="Select Theme > " || true)"
            fi

            if [[ -z "$CHOSEN" ]]; then
                exit 0
            fi

            case "$CHOSEN" in
                *Latte*)             TARGET_THEME="catppuccin-latte" ;;
                *Catppuccin*)        TARGET_THEME="catppuccin" ;;
                *Night*Light*)       TARGET_THEME="tokyo-night-light" ;;
                *Tokyo*)             TARGET_THEME="tokyo-night" ;;
                *Monochrome*Light*)  TARGET_THEME="monochrome-light" ;;
                *Monochrome*)        TARGET_THEME="monochrome" ;;
                *)                   TARGET_THEME="$(normalize_theme "$CHOSEN")" ;;
            esac
            ;;
        -s|--set)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --set requires a theme argument." >&2
                echo "Allowed themes: ${ALLOWED_THEMES[*]}" >&2
                exit 1
            fi
            TARGET_THEME="$(normalize_theme "$2")"
            ;;
        *)
            TARGET_THEME="$(normalize_theme "$1")"
            ;;
    esac
fi

# Validation
if ! is_valid_theme "$TARGET_THEME"; then
    echo "Error: Invalid theme '$TARGET_THEME'." >&2
    echo "Allowed themes are: ${ALLOWED_THEMES[*]}" >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# 1. Update Persistent State
# ------------------------------------------------------------------------------
echo "$TARGET_THEME" > "$STATE_FILE"
echo "$TARGET_THEME" > "$HYPR_STATE_FILE"

# ------------------------------------------------------------------------------
# 2. Update Waybar & Wofi Theme Symlinks
# ------------------------------------------------------------------------------
apply_theme_to_dir() {
    local dir="$1"
    local theme="$2"
    if [[ -d "$dir" && -d "$dir/themes" ]]; then
        if [[ -f "$dir/themes/${theme}.css" ]]; then
            ln -snf "themes/${theme}.css" "$dir/theme.css"
            if [[ -f "$dir/style.css" ]]; then
                touch "$dir/style.css"
            fi
        fi
    fi
}

apply_wofi_theme() {
    local dir="$1"
    local theme="$2"
    if [[ -d "$dir" && -d "$dir/themes" ]]; then
        if [[ -f "$dir/themes/${theme}.css" ]]; then
            ln -snf "themes/${theme}.css" "$dir/theme.css"
            # Compile self-contained CSS to prevent Wofi relative @import failures
            if [[ -f "$dir/style-base.css" ]]; then
                cat "$dir/themes/${theme}.css" "$dir/style-base.css" > "$dir/style.css"
            elif [[ -f "$dir/style.css" ]]; then
                touch "$dir/style.css"
            fi
            if [[ -f "$dir/wallpicker-base.css" ]]; then
                cat "$dir/themes/${theme}.css" "$dir/wallpicker-base.css" > "$dir/wallpicker.css"
            fi
        fi
    fi
}

if [[ -n "$REPO_WAYBAR_DIR" ]]; then
    apply_theme_to_dir "$REPO_WAYBAR_DIR" "$TARGET_THEME"
fi

if [[ -n "$USER_WAYBAR_DIR" && "$USER_WAYBAR_DIR" != "$REPO_WAYBAR_DIR" ]]; then
    apply_theme_to_dir "$USER_WAYBAR_DIR" "$TARGET_THEME"
fi

if [[ -n "$REPO_WOFI_DIR" ]]; then
    apply_wofi_theme "$REPO_WOFI_DIR" "$TARGET_THEME"
fi

if [[ -n "$USER_WOFI_DIR" && "$USER_WOFI_DIR" != "$REPO_WOFI_DIR" ]]; then
    apply_wofi_theme "$USER_WOFI_DIR" "$TARGET_THEME"
fi

# ------------------------------------------------------------------------------
# 3. Reload Waybar
# ------------------------------------------------------------------------------
if pgrep -u "$(id -u)" -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR2 -u "$(id -u)" -x waybar 2>/dev/null || true
    killall -SIGUSR2 -q waybar 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 4. Synchronize Hyprland Border Accents & Persistent Configs
# ------------------------------------------------------------------------------
update_hyprland_configs() {
    local theme="$1"
    local active_col=""
    local inactive_col=""
    local lua_colors=""

    case "$theme" in
        catppuccin)
            active_col="rgba(cba6f7ee) rgba(89b4faee) 45deg"
            inactive_col="rgba(313244aa)"
            lua_colors='{"rgba(cba6f7ee)", "rgba(89b4faee)"}'
            ;;
        tokyo-night)
            active_col="rgba(7aa2f7ee) rgba(7dcfffee) 45deg"
            inactive_col="rgba(24283baa)"
            lua_colors='{"rgba(7aa2f7ee)", "rgba(7dcfffee)"}'
            ;;
        monochrome)
            active_col="rgba(ffffffee) rgba(aaaaaaee) 45deg"
            inactive_col="rgba(333333aa)"
            lua_colors='{"rgba(ffffffee)", "rgba(aaaaaaee)"}'
            ;;
        catppuccin-latte)
            active_col="rgba(1e66f5ee) rgba(8839efee) 45deg"
            inactive_col="rgba(bcc0ccaa)"
            lua_colors='{"rgba(1e66f5ee)", "rgba(8839efee)"}'
            ;;
        tokyo-night-light)
            active_col="rgba(2e7de9ee) rgba(007197ee) 45deg"
            inactive_col="rgba(c4c8daaa)"
            lua_colors='{"rgba(2e7de9ee)", "rgba(007197ee)"}'
            ;;
        monochrome-light)
            active_col="rgba(222222ee) rgba(555555ee) 45deg"
            inactive_col="rgba(ccccccaa)"
            lua_colors='{"rgba(222222ee)", "rgba(555555ee)"}'
            ;;
    esac

    local conf_files=(
        "$SCRIPT_DIR/../conf.d/look-and-feel.conf"
        "$SCRIPT_DIR/../../vanilla/hypr/conf.d/look-and-feel.conf"
        "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/conf.d/look-and-feel.conf"
    )
    local lua_files=(
        "$SCRIPT_DIR/../hyprland.lua"
        "$SCRIPT_DIR/../../vanilla/hypr/hyprland.lua"
        "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua"
    )

    for cf in "${conf_files[@]}"; do
        if [[ -f "$cf" ]]; then
            sed -i "s|col\.active_border = .*|col.active_border = $active_col|" "$cf" 2>/dev/null || true
            sed -i "s|col\.inactive_border = .*|col.inactive_border = $inactive_col|" "$cf" 2>/dev/null || true
        fi
    done

    for lf in "${lua_files[@]}"; do
        if [[ -f "$lf" ]]; then
            sed -i "s|active_border   = { colors = {.*}, angle = [0-9]* }|active_border   = { colors = $lua_colors, angle = 45 }|" "$lf" 2>/dev/null || true
            sed -i "s|inactive_border = \".*\"|inactive_border = \"$inactive_col\"|" "$lf" 2>/dev/null || true
        fi
    done
}

update_hyprtoolkit_conf() {
    local theme="$1"
    local accent_hex=""
    local bg_hex=""
    local text_hex=""
    case "$theme" in
        catppuccin)
            accent_hex="0xFFcba6f7"
            bg_hex="0xFF1e1e2e"
            text_hex="0xFFcdd6f4"
            ;;
        tokyo-night)
            accent_hex="0xFF7aa2f7"
            bg_hex="0xFF1a1b26"
            text_hex="0xFFc0caf5"
            ;;
        monochrome)
            accent_hex="0xFFffffff"
            bg_hex="0xFF121212"
            text_hex="0xFFe0e0e0"
            ;;
        catppuccin-latte)
            accent_hex="0xFF8839ef"
            bg_hex="0xFFeff1f5"
            text_hex="0xFF4c4f69"
            ;;
        tokyo-night-light)
            accent_hex="0xFF2e7de9"
            bg_hex="0xFFe1e2e7"
            text_hex="0xFF3760bf"
            ;;
        monochrome-light)
            accent_hex="0xFF222222"
            bg_hex="0xFFf5f5f5"
            text_hex="0xFF1a1a1a"
            ;;
    esac

    local tk_files=(
        "$SCRIPT_DIR/../hyprtoolkit.conf"
        "$SCRIPT_DIR/../../vanilla/hypr/hyprtoolkit.conf"
        "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprtoolkit.conf"
    )
    for tf in "${tk_files[@]}"; do
        if [[ -f "$tf" ]]; then
            cat > "$tf" << EOF
# ==============================================================================
# Hyprtoolkit Configuration (Hyprland GUI & Hyprlauncher Styling)
# ==============================================================================

# Interface typography - dynamically inherits system monospace font
font_family = monospace
font_family_monospace = monospace

# Typography sizing
font_size = 11
small_font_size = 10
h1_size = 18
h2_size = 14
h3_size = 12

# Palette synchronization
background = $bg_hex
base = $bg_hex
text = $text_hex
accent = $accent_hex
EOF
        fi
    done
}

update_hyprland_configs "$TARGET_THEME"
update_hyprtoolkit_conf "$TARGET_THEME"

# Live Compositor Update
if command -v hyprctl >/dev/null 2>&1; then
    case "$TARGET_THEME" in
        catppuccin)
            hyprctl keyword general:col.active_border "rgba(cba6f7ee) rgba(89b4faee) 45deg" >/dev/null 2>&1 || true
            hyprctl keyword general:col.inactive_border "rgba(313244aa)" >/dev/null 2>&1 || true
            ;;
        tokyo-night)
            hyprctl keyword general:col.active_border "rgba(7aa2f7ee) rgba(7dcfffee) 45deg" >/dev/null 2>&1 || true
            hyprctl keyword general:col.inactive_border "rgba(24283baa)" >/dev/null 2>&1 || true
            ;;
        monochrome)
            hyprctl keyword general:col.active_border "rgba(ffffffee) rgba(aaaaaaee) 45deg" >/dev/null 2>&1 || true
            hyprctl keyword general:col.inactive_border "rgba(333333aa)" >/dev/null 2>&1 || true
            ;;
        catppuccin-latte)
            hyprctl keyword general:col.active_border "rgba(1e66f5ee) rgba(8839efee) 45deg" >/dev/null 2>&1 || true
            hyprctl keyword general:col.inactive_border "rgba(bcc0ccaa)" >/dev/null 2>&1 || true
            ;;
        tokyo-night-light)
            hyprctl keyword general:col.active_border "rgba(2e7de9ee) rgba(007197ee) 45deg" >/dev/null 2>&1 || true
            hyprctl keyword general:col.inactive_border "rgba(c4c8daaa)" >/dev/null 2>&1 || true
            ;;
        monochrome-light)
            hyprctl keyword general:col.active_border "rgba(222222ee) rgba(555555ee) 45deg" >/dev/null 2>&1 || true
            hyprctl keyword general:col.inactive_border "rgba(ccccccaa)" >/dev/null 2>&1 || true
            ;;
    esac
fi

# ------------------------------------------------------------------------------
# 5. User Feedback & Notification
# ------------------------------------------------------------------------------
echo "Switched theme to: $TARGET_THEME (Waybar, Borders, Launcher)"

if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Theme Controller" "Theme Switched" "Active theme: $TARGET_THEME (Waybar, Borders, Launcher)" -i preferences-desktop-theme 2>/dev/null || true
fi
