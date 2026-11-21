#!/usr/bin/env bash
# ==============================================================================
# GNOME Theme Importer for Hyprland / Wayland Sessions
# ==============================================================================
# Reads current GNOME / dconf appearance preferences (GTK theme, icon theme,
# cursor theme, cursor size, fonts, and dark mode color scheme) and imports
# them into the active Wayland session, Hyprland cursor manager, systemd/DBus
# user environment, and GTK 3/4 settings files.
# Gracefully falls back to cohesive defaults in non-GNOME environments.
# ==============================================================================
set -euo pipefail

log_info() { echo "  [THEME] $*"; }

# ------------------------------------------------------------------------------
# 1. Query GNOME / GSettings Settings with Graceful Fallbacks
# ------------------------------------------------------------------------------
GTK_THEME="Adwaita"
ICON_THEME="Adwaita"
CURSOR_THEME="Adwaita"
CURSOR_SIZE=24
FONT_NAME="Adwaita Sans 11"
DOC_FONT_NAME="Adwaita Sans 12"
MONO_FONT_NAME="Adwaita Mono 11"
COLOR_SCHEME="default"
ACCENT_COLOR="blue"

if command -v gsettings >/dev/null 2>&1; then
    get_setting() {
        local schema="$1"
        local key="$2"
        local fallback="$3"
        local val
        val="$(gsettings get "$schema" "$key" 2>/dev/null | tr -d "'\"" || true)"
        if [[ -n "$val" && "$val" != "null" && "$val" != "@as []" ]]; then
            echo "$val"
        else
            echo "$fallback"
        fi
    }

    GTK_THEME="$(get_setting org.gnome.desktop.interface gtk-theme "$GTK_THEME")"
    ICON_THEME="$(get_setting org.gnome.desktop.interface icon-theme "$ICON_THEME")"
    CURSOR_THEME="$(get_setting org.gnome.desktop.interface cursor-theme "$CURSOR_THEME")"
    CURSOR_SIZE="$(get_setting org.gnome.desktop.interface cursor-size "$CURSOR_SIZE")"
    FONT_NAME="$(get_setting org.gnome.desktop.interface font-name "$FONT_NAME")"
    DOC_FONT_NAME="$(get_setting org.gnome.desktop.interface document-font-name "$DOC_FONT_NAME")"
    MONO_FONT_NAME="$(get_setting org.gnome.desktop.interface monospace-font-name "$MONO_FONT_NAME")"
    COLOR_SCHEME="$(get_setting org.gnome.desktop.interface color-scheme "$COLOR_SCHEME")"
    ACCENT_COLOR="$(get_setting org.gnome.desktop.interface accent-color "$ACCENT_COLOR")"
fi

# Ensure cursor theme exists on system; fallback to Adwaita or default
if [[ ! -d "/usr/share/icons/$CURSOR_THEME" && ! -d "$HOME/.icons/$CURSOR_THEME" && ! -d "$HOME/.local/share/icons/$CURSOR_THEME" ]]; then
    if [[ -d "/usr/share/icons/Adwaita" ]]; then
        CURSOR_THEME="Adwaita"
    fi
fi

# Determine dark mode preference
PREFER_DARK=false
if [[ "$COLOR_SCHEME" == "prefer-dark" || "$GTK_THEME" == *"-dark"* ]]; then
    PREFER_DARK=true
fi

# ------------------------------------------------------------------------------
# 2. Synchronize GSettings / Dconf State (Emits DBus signals for active apps)
# ------------------------------------------------------------------------------
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
    # Only ensure monospace font is configured; never mutate system sans-serif or document fonts
    gsettings set org.gnome.desktop.interface monospace-font-name "$MONO_FONT_NAME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface accent-color "$ACCENT_COLOR" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 3. Synchronize Hyprland Cursor Engine
# ------------------------------------------------------------------------------
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE" >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# 4. Export Cursor & Theme Environment to Systemd & DBus User Sessions
# ------------------------------------------------------------------------------
# 4. Clean GTK_THEME and Export Cursor & Environment to Systemd & DBus
# ------------------------------------------------------------------------------
unset GTK_THEME 2>/dev/null || true

export XCURSOR_THEME="$CURSOR_THEME"
export XCURSOR_SIZE="$CURSOR_SIZE"
export HYPRCURSOR_THEME="$CURSOR_THEME"
export HYPRCURSOR_SIZE="$CURSOR_SIZE"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user unset-environment GTK_THEME 2>/dev/null || true
    systemctl --user import-environment \
        XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE 2>/dev/null || true
fi

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd \
        XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 5. Synchronize GTK 3 & GTK 4 Configuration Files
# ------------------------------------------------------------------------------
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/gtk-4.0" "$HOME/.icons/default" 2>/dev/null || true

if [[ -d "$CONFIG_DIR/gtk-3.0" && -w "$CONFIG_DIR/gtk-3.0" ]]; then
    cat > "$CONFIG_DIR/gtk-3.0/settings.ini" << EOF || true
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-font-name=$FONT_NAME
gtk-application-prefer-dark-theme=$PREFER_DARK
EOF
fi

CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
if echo "$CURRENT_DESKTOP" | grep -qi "gnome"; then
    rm -f "$CONFIG_DIR/gtk-4.0/settings.ini" 2>/dev/null || true
elif [[ -d "$CONFIG_DIR/gtk-4.0" && -w "$CONFIG_DIR/gtk-4.0" ]]; then
    cat > "$CONFIG_DIR/gtk-4.0/settings.ini" << EOF || true
[Settings]
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-font-name=$FONT_NAME
EOF
fi

# X11 / XWayland Default Cursor Pointer
if [[ -d "$HOME/.icons/default" && -w "$HOME/.icons/default" ]]; then
    cat > "$HOME/.icons/default/index.theme" << EOF || true
[icon theme]
Inherits=$CURSOR_THEME
EOF
fi

# ------------------------------------------------------------------------------
# 6. KDE / Qt Theme Notification Broadcast
# ------------------------------------------------------------------------------
if command -v dbus-send >/dev/null 2>&1; then
    dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
fi

log_info "Imported GNOME Theme successfully: Theme=${GTK_THEME:-Adwaita}, Icons=$ICON_THEME, Cursor=$CURSOR_THEME ($CURSOR_SIZE), Font=$FONT_NAME, Scheme=$COLOR_SCHEME"
exit 0
