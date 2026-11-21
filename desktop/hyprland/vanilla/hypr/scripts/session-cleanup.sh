#!/usr/bin/env bash
# ==============================================================================
# Hyprland Session Cleanup Daemon
# Automatically resets systemd user graphical-session targets on Hyprland exit
# Guarantees zero session-collision when returning to GDM or switching to GNOME
# ==============================================================================
set -euo pipefail

# Wait while Hyprland process is alive
while pgrep -u "$USER" -x Hyprland >/dev/null 2>&1; do
    sleep 1
done

# Hyprland has stopped: deactivate graphical session targets in systemd user manager
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user stop graphical-session.target 2>/dev/null || true
    systemctl --user stop graphical-session-pre.target 2>/dev/null || true
    systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP 2>/dev/null || true
fi

exit 0
