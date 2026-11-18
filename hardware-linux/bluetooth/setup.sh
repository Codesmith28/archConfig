#!/usr/bin/env bash
# ==============================================================================
# Bluetooth Audio & Intel AX211 Hardware Optimization Setup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_DEST="${1:-/usr/lib/systemd/system-sleep}"
[ -d "$HOOK_DEST" ] || HOOK_DEST="/etc/systemd/system-sleep"

run_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo -e "\033[1;33m[WARN]\033[0m Root privileges required for: $*" >&2
        return 1
    fi
}

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    echo "=== Bluetooth Hardware & Sleep Status Check ==="
    if [[ -f /etc/modprobe.d/btusb.conf ]]; then
        echo "btusb.conf: installed (/etc/modprobe.d/btusb.conf)"
        grep -q "force_scofix=1" /etc/modprobe.d/btusb.conf && echo "  • Intel SCO buffer alignment (force_scofix=1): active"
        grep -q "enable_autosuspend=0" /etc/modprobe.d/btusb.conf && echo "  • Audio stream autosuspend block (enable_autosuspend=0): active"
    else
        echo "btusb.conf: NOT found in /etc/modprobe.d/"
    fi
    if [[ -f /etc/udev/rules.d/50-btusb-power.rules ]]; then
        echo "50-btusb-power.rules: installed (/etc/udev/rules.d/50-btusb-power.rules)"
    else
        echo "50-btusb-power.rules: not found in /etc/udev/rules.d/"
    fi
    if [[ -x /usr/lib/systemd/system-sleep/bluetooth-sleep.sh || -x /etc/systemd/system-sleep/bluetooth-sleep.sh ]]; then
        echo "bluetooth-sleep.sh hook: installed and executable"
    else
        echo "bluetooth-sleep.sh hook: not found in system-sleep"
    fi
    if [[ -f /etc/bluetooth/main.conf ]]; then
        echo "main.conf: /etc/bluetooth/main.conf present"
        grep -qi "^[[:space:]]*FastConnectable[[:space:]]*=[[:space:]]*true" /etc/bluetooth/main.conf && echo "  • FastConnectable: active" || echo "  • FastConnectable: not enabled"
        grep -qi "^[[:space:]]*Experimental[[:space:]]*=[[:space:]]*true" /etc/bluetooth/main.conf && echo "  • Battery reporting & LE Audio (Experimental): active" || echo "  • Battery reporting (Experimental): not enabled"
        grep -qi "^[[:space:]]*MultiProfile[[:space:]]*=[[:space:]]*multiple" /etc/bluetooth/main.conf && echo "  • MultiProfile (A2DP + HFP): active" || echo "  • MultiProfile: not enabled"
        grep -qi "^[[:space:]]*AutoEnable[[:space:]]*=[[:space:]]*true" /etc/bluetooth/main.conf && echo "  • Controller AutoEnable: active" || echo "  • Controller AutoEnable: not enabled"
    fi
    if [[ -f /etc/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf || -f "$HOME/.config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf" ]]; then
        echo "wireplumber quality config: active"
    else
        echo "wireplumber quality config: NOT found"
    fi
    echo "bluetooth.service status: $(systemctl is-active bluetooth.service 2>/dev/null || echo 'inactive')"
    exit 0
fi

# 1. Install btusb modprobe configuration and USB power udev rule (Intel AX211 SCO packet fix)
if [[ -f "$SCRIPT_DIR/btusb.conf" ]]; then
    echo "Installing btusb kernel configuration..."
    run_root cp "$SCRIPT_DIR/btusb.conf" /etc/modprobe.d/btusb.conf || true
    run_root chmod 644 /etc/modprobe.d/btusb.conf || true
fi
if [[ -f "$SCRIPT_DIR/50-btusb-power.rules" ]]; then
    echo "Installing btusb USB power control udev rule..."
    run_root mkdir -p /etc/udev/rules.d/ || true
    run_root cp "$SCRIPT_DIR/50-btusb-power.rules" /etc/udev/rules.d/50-btusb-power.rules || true
    run_root chmod 644 /etc/udev/rules.d/50-btusb-power.rules || true
    run_root udevadm control --reload-rules >/dev/null 2>&1 || true
    run_root udevadm trigger --subsystem-match=usb >/dev/null 2>&1 || true
fi

# 2. Configure BlueZ main.conf (FastConnectable, Battery reporting, AutoEnable, MultiProfile)
if [[ -f "$SCRIPT_DIR/main.conf" && -f /etc/bluetooth/main.conf ]]; then
    echo "Configuring BlueZ main.conf optimizations..."
    run_root sed -i 's|^#*[[:space:]]*FastConnectable[[:space:]]*=.*|FastConnectable = true|' /etc/bluetooth/main.conf || true
    run_root sed -i 's|^#*[[:space:]]*JustWorksRepairing[[:space:]]*=.*|JustWorksRepairing = always|' /etc/bluetooth/main.conf || true
    run_root sed -i 's|^#*[[:space:]]*Experimental[[:space:]]*=.*|Experimental = true|' /etc/bluetooth/main.conf || true
    run_root sed -i 's|^#*[[:space:]]*MultiProfile[[:space:]]*=.*|MultiProfile = multiple|' /etc/bluetooth/main.conf || true
    run_root sed -i 's|^#*[[:space:]]*AutoEnable[[:space:]]*=.*|AutoEnable = true|' /etc/bluetooth/main.conf || true
    run_root sed -i 's|^#*[[:space:]]*ReconnectAttempts[[:space:]]*=.*|ReconnectAttempts = 7|' /etc/bluetooth/main.conf || true
    run_root sed -i 's|^#*[[:space:]]*ReconnectIntervals[[:space:]]*=.*|ReconnectIntervals = 1, 2, 4, 8, 16, 32, 64|' /etc/bluetooth/main.conf || true
    if command -v systemctl >/dev/null 2>&1; then
        run_root systemctl try-restart bluetooth.service 2>/dev/null || true
    fi
fi

# 3. Install bluetooth sleep hook
if [[ -f "$SCRIPT_DIR/bluetooth-sleep.sh" ]]; then
    echo "Installing bluetooth-sleep hook to $HOOK_DEST..."
    run_root mkdir -p "$HOOK_DEST" || true
    run_root cp "$SCRIPT_DIR/bluetooth-sleep.sh" "$HOOK_DEST/bluetooth-sleep.sh" || true
    run_root chmod +x "$HOOK_DEST/bluetooth-sleep.sh" || true
fi

# 4. Install WirePlumber quality configuration (system-wide and user-specific)
WP_CONF_SRC="$REPO_DIR/core/config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf"
if [[ -f "$WP_CONF_SRC" ]]; then
    echo "Installing WirePlumber quality configuration..."
    run_root mkdir -p /etc/wireplumber/wireplumber.conf.d/ || true
    run_root cp "$WP_CONF_SRC" /etc/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf || true
    run_root chmod 644 /etc/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf || true

    target_user="${SUDO_USER:-$USER}"
    user_home="$(getent passwd "$target_user" 2>/dev/null | cut -d: -f6 || echo "$HOME")"
    if [[ -n "$user_home" && -d "$user_home" ]]; then
        user_wp_dir="$user_home/.config/wireplumber/wireplumber.conf.d"
        mkdir -p "$user_wp_dir"
        ln -sf "$WP_CONF_SRC" "$user_wp_dir/50-bluetooth-quality.conf"
        if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
            chown -R "$target_user":"$target_user" "$user_home/.config/wireplumber" 2>/dev/null || true
        fi
    fi
fi

# 5. Restart user audio services if running in user session
if [[ "$(id -u)" -ne 0 ]]; then
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user restart wireplumber pipewire pipewire-pulse 2>/dev/null || true
    fi
else
    echo "Tip: Run as non-root to restart user audio stack, or execute:"
    echo "  systemctl --user restart wireplumber pipewire pipewire-pulse"
fi

echo "Bluetooth hardware configuration and audio autoswitch installed successfully."
