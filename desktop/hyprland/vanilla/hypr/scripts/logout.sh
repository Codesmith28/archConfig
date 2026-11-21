#!/usr/bin/env bash
# ==============================================================================
# Hyprland Universal Robust Logout Routine
# Supports: UWSM, systemd-logind, direct compositor dispatch, and process cleanup
# Zero-hang, reliable session termination and clean state reset for GNOME/GDM
# ==============================================================================
set -euo pipefail

# 1. Close active popups, menus, and notification center
pkill -x swaync 2>/dev/null || true
pkill -x wofi 2>/dev/null || true
pkill -x rofi 2>/dev/null || true
pkill -x quickshell 2>/dev/null || true

# 2. Universal Wayland Session Manager (UWSM) stop
if command -v uwsm >/dev/null 2>&1; then
    if [[ -n "${UWSM_APP_ID:-}" ]] || uwsm check may-start >/dev/null 2>&1 || pgrep -x uwsm >/dev/null 2>&1; then
        uwsm stop 2>/dev/null || true
    fi
fi

# 3. Direct Hyprland compositor dispatch
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl dispatch exit 2>/dev/null || true
fi

# 4. Deactivate systemd user graphical-session targets to allow clean GDM/GNOME re-entry
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user stop graphical-session.target 2>/dev/null || true
    systemctl --user stop graphical-session-pre.target 2>/dev/null || true
    systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP 2>/dev/null || true
fi

# 5. Terminate logind session if session ID is available
if [[ -n "${XDG_SESSION_ID:-}" ]]; then
    loginctl terminate-session "$XDG_SESSION_ID" 2>/dev/null || true
fi

# 6. Fallback: Lookup user session from loginctl
user_session="$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$USER" '$3 == u {print $1; exit}' || true)"
if [[ -n "$user_session" ]]; then
    loginctl terminate-session "$user_session" 2>/dev/null || true
fi

# 7. Fallback: Terminate Hyprland process tree directly
if pgrep -u "$USER" -x Hyprland >/dev/null 2>&1; then
    pkill -x -u "$USER" Hyprland 2>/dev/null || true
    sleep 0.2
    pkill -9 -x -u "$USER" Hyprland 2>/dev/null || true
fi

exit 0
