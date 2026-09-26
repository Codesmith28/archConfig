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
    log_info()    { echo "[INFO] $*"; }
    log_success() { echo "[OK]   $*"; }
    log_warn()    { echo "[WARN] $*" >&2; }
    log_error()   { echo "[ERR]  $*" >&2; }
fi

log_info "Applying GNOME and Ptyxis keybindings and shortcuts..."

if [[ "$(id -u)" -eq 0 ]]; then
    TARGET_USER="${SUDO_USER:-}"
    if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
        TARGET_USER="$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $3}' | grep -v 'root' | head -n 1 || true)"
        if [[ -z "$TARGET_USER" ]]; then
            TARGET_USER="$(who | awk '$1 != "root" {print $1; exit}' || true)"
        fi
        if [[ -z "$TARGET_USER" ]]; then
            TARGET_USER="codesmith28"
        fi
    fi

    TARGET_UID=$(id -u "$TARGET_USER")
    TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    BUS_PATH="/run/user/${TARGET_UID}/bus"

    if [[ ! -S "$BUS_PATH" ]]; then
        log_warn "D-Bus session bus not found at $BUS_PATH. GNOME session might not be active for $TARGET_USER."
    fi

    log_info "Running GNOME configuration as user ${TARGET_USER} (UID: ${TARGET_UID})..."
    sudo -u "$TARGET_USER" -H env \
        HOME="$TARGET_HOME" \
        USER="$TARGET_USER" \
        XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=${BUS_PATH}" \
        bash "$SCRIPT_DIR/config.sh"
else
    bash "$SCRIPT_DIR/config.sh"
fi

log_success "GNOME settings applied successfully!"
