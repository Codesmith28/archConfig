#!/bin/bash

# A file to keep track of the current state
STATE_FILE="$HOME/.cache/hyprland_theme_state"

# Determine current state; default to light if file doesn't exist
if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE")" == "light" ]; then
    CURRENT="light"
else
    CURRENT="dark"
fi

if [ "$CURRENT" == "light" ]; then
    # ==========================================
    # SWITCH TO DARK MODE
    # ==========================================
    echo "dark" > "$STATE_FILE"

    # 1. System/Web Apps (VS Code, Zen, GTK)
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'

    # 2. KDE/Qt Apps (Dolphin)
    # This natively applies the KDE color scheme and sends the DBus signal to update instantly
    plasma-apply-colorscheme BreezeDark

    # 3. Hyprland Specifics (Change your borders, optional)
    hyprctl keyword general:col.active_border "rgba(33ccffee) rgba(00ff99ee) 45deg"
    hyprctl keyword general:col.inactive_border "rgba(595959aa)"

else
    # ==========================================
    # SWITCH TO LIGHT MODE
    # ==========================================
    echo "light" > "$STATE_FILE"

    # 1. System/Web Apps (VS Code, Zen, GTK)
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme 'Breeze'

    # 2. KDE/Qt Apps (Dolphin)
    plasma-apply-colorscheme BreezeLight

    # 3. Hyprland Specifics (Change your borders, optional)
    hyprctl keyword general:col.active_border "rgba(ffb86cee) rgba(ff79c6ee) 45deg"
    hyprctl keyword general:col.inactive_border "rgba(595959aa)"
fi

# Failsafe: Broadcast KDE Global Settings change to all Qt/KDE apps directly via DBus
# This ensures that apps like Dolphin catch the change even if KDED isn't tracking it properly
dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0
