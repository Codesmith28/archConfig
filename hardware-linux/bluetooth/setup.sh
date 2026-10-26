#!/usr/bin/env bash
# ==============================================================================
# Bluetooth Revert & System Stock Defaults Restorer
# ==============================================================================
# Completely reverts and cleans up all custom Bluetooth, BlueZ, WirePlumber,
# and btusb overrides, restoring 100% stock upstream Linux/Fedora defaults.
# ==============================================================================
set -euo pipefail

log_info()    { echo -e "\033[0;34m[INFO]\033[0m $*"; }
log_success() { echo -e "\033[0;32m[OK]\033[0m   $*"; }
log_warn()    { echo -e "\033[1;33m[WARN]\033[0m $*" >&2; }

run_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        log_warn "Root privileges required for: $*"
        return 1
    fi
}

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    echo "=== Bluetooth Configuration & Status Check ==="
    if [[ -f /etc/modprobe.d/btusb.conf ]]; then
        echo "btusb.conf: CUSTOM OVERRIDE PRESENT (/etc/modprobe.d/btusb.conf)"
    else
        echo "btusb.conf: None (stock kernel module defaults active)"
    fi

    if [[ -f /usr/lib/systemd/system-sleep/bluetooth-sleep.sh || -f /etc/systemd/system-sleep/bluetooth-sleep.sh ]]; then
        echo "bluetooth-sleep.sh: CUSTOM HOOK PRESENT"
    else
        echo "bluetooth-sleep.sh: None (stock systemd-sleep defaults active)"
    fi

    if [[ -d "$HOME/.config/wireplumber" ]]; then
        echo "user wireplumber config: PRESENT ($HOME/.config/wireplumber)"
    else
        echo "user wireplumber config: None (stock WirePlumber SPA defaults active)"
    fi

    echo "bluetooth.service status: $(systemctl is-active bluetooth.service 2>/dev/null || echo 'inactive')"
    exit 0
fi

log_info "Reverting all archConfig Bluetooth customizations to stock system defaults..."

# 1. Remove btusb kernel modprobe overrides
if [[ -f /etc/modprobe.d/btusb.conf ]]; then
    log_info "Removing /etc/modprobe.d/btusb.conf..."
    run_root rm -f /etc/modprobe.d/btusb.conf
    log_success "Removed /etc/modprobe.d/btusb.conf"
fi

# 2. Remove systemd-sleep hooks
for hook in /usr/lib/systemd/system-sleep/bluetooth-sleep.sh /etc/systemd/system-sleep/bluetooth-sleep.sh; do
    if [[ -f "$hook" ]]; then
        log_info "Removing $hook..."
        run_root rm -f "$hook"
        log_success "Removed $hook"
    fi
done

# 3. Revert systemd units and clean service state
log_info "Reverting and cleaning systemd bluetooth units..."
run_root systemctl revert bluetooth.service bluetooth.target 2>/dev/null || true
run_root systemctl clean bluetooth.service 2>/dev/null || true

# 4. Revert /etc/bluetooth/main.conf to stock system defaults
if [[ -f /etc/bluetooth/main.conf ]]; then
    log_info "Restoring /etc/bluetooth/main.conf to stock defaults..."
    run_root sed -i 's|^[[:space:]]*MultiProfile[[:space:]]*=.*|#MultiProfile = off|' /etc/bluetooth/main.conf
    run_root sed -i 's|^[[:space:]]*FastConnectable[[:space:]]*=.*|#FastConnectable = false|' /etc/bluetooth/main.conf
    run_root sed -i 's|^[[:space:]]*JustWorksRepairing[[:space:]]*=.*|#JustWorksRepairing = never|' /etc/bluetooth/main.conf
    run_root sed -i 's|^[[:space:]]*Experimental[[:space:]]*=.*|#Experimental = false|' /etc/bluetooth/main.conf
    run_root sed -i 's|^[[:space:]]*KernelExperimental[[:space:]]*=.*|#KernelExperimental = false|' /etc/bluetooth/main.conf
    run_root sed -i 's|^[[:space:]]*ReconnectAttempts[[:space:]]*=.*|#ReconnectAttempts=7|' /etc/bluetooth/main.conf
    run_root sed -i 's|^[[:space:]]*ReconnectIntervals[[:space:]]*=.*|#ReconnectIntervals=1,2,4,8,16,32,64|' /etc/bluetooth/main.conf
    run_root sed -i 's|^[[:space:]]*AutoEnable[[:space:]]*=.*|#AutoEnable=true|' /etc/bluetooth/main.conf
    log_success "Restored /etc/bluetooth/main.conf"
fi

# 5. Clean up any custom user-space WirePlumber configs
if [[ -L "$HOME/.config/wireplumber" || -d "$HOME/.config/wireplumber" ]]; then
    log_info "Removing custom WirePlumber config ($HOME/.config/wireplumber)..."
    rm -rf "$HOME/.config/wireplumber"
    log_success "Removed custom WirePlumber config"
fi

if [[ -f "$HOME/.local/share/wireplumber/scripts/device/autoswitch-bluetooth-profile.lua" ]]; then
    rm -f "$HOME/.local/share/wireplumber/scripts/device/autoswitch-bluetooth-profile.lua"
fi

# 6. Reload systemd and restart Bluetooth daemon
run_root systemctl daemon-reload
run_root systemctl try-restart bluetooth.service 2>/dev/null || true

# 7. Restart user audio services if available
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user restart pipewire wireplumber pipewire-pulse 2>/dev/null || true
fi

log_success "All Bluetooth settings successfully reverted to 100% stock upstream defaults."
