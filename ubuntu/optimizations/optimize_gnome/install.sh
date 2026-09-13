#!/usr/bin/env bash
# ==============================================================================
# GNOME Desktop Configuration Installer
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
else
    echo "[INFO] Configuring GNOME settings..."
fi

log_info "Applying GNOME and Ptyxis keybindings and shortcuts..."

if [[ "$(id -u)" -eq 0 && -n "$SUDO_USER" ]]; then
    USER_UID=$(id -u "$SUDO_USER")
    sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${USER_UID}/bus" bash "$SCRIPT_DIR/config.sh"
else
    bash "$SCRIPT_DIR/config.sh"
fi

log_success "GNOME settings applied successfully!"
