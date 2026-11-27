#!/usr/bin/env bash
# ==============================================================================
# Bluetooth Audio & Intel AX211 Hardware Optimization Setup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

MODE="install"
HOOK_DEST=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verify|-v|verify|status)
            MODE="verify"
            shift
            ;;
        --hook-dest)
            if [[ $# -lt 2 || -z "${2:-}" ]]; then
                echo "Missing value for --hook-dest" >&2
                exit 1
            fi
            HOOK_DEST="$2"
            shift 2
            ;;
        bluetooth)
            # Master hardware-linux/setup.sh forwards module name arguments
            shift
            ;;
        *)
            if [[ -z "$HOOK_DEST" && "$1" == /* ]]; then
                HOOK_DEST="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$HOOK_DEST" ]]; then
    if [[ -d /usr/lib/systemd/system-sleep ]]; then
        HOOK_DEST="/usr/lib/systemd/system-sleep"
    else
        HOOK_DEST="/etc/systemd/system-sleep"
    fi
fi

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

restart_user_audio() {
    command -v systemctl >/dev/null 2>&1 || return 0

    if [[ "$(id -u)" -ne 0 ]]; then
        systemctl --user restart wireplumber pipewire pipewire-pulse 2>/dev/null || true
        return 0
    fi

    local target_user="${SUDO_USER:-}"
    if [[ -n "$target_user" && "$target_user" != "root" ]]; then
        local target_uid
        target_uid="$(id -u "$target_user" 2>/dev/null || true)"
        if [[ -n "$target_uid" && -S "/run/user/$target_uid/bus" ]]; then
            sudo -u "$target_user" env \
                XDG_RUNTIME_DIR="/run/user/$target_uid" \
                DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$target_uid/bus" \
                systemctl --user restart wireplumber pipewire pipewire-pulse 2>/dev/null || true
            return 0
        fi
    fi

    echo "Tip: Restart user audio stack to re-sync PipeWire/WirePlumber with BlueZ:"
    echo "  systemctl --user restart wireplumber pipewire pipewire-pulse"
}

set_ini_key() {
    local file="$1"
    local section="$2"
    local key="$3"
    local value="$4"

    run_root python3 - "$file" "$section" "$key" "$value" << 'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
section, key, value = sys.argv[2], sys.argv[3], sys.argv[4]
lines = path.read_text(encoding="utf-8").splitlines(keepends=True)

sec_re = re.compile(rf"^\s*\[{re.escape(section)}\]\s*$")
any_sec_re = re.compile(r"^\s*\[[^\]]+\]\s*$")
key_re = re.compile(rf"^\s*#*\s*{re.escape(key)}\s*=.*$")

in_sec = False
sec_end_idx = None
replaced = False
out = []

for idx, line in enumerate(lines):
    if sec_re.match(line):
        in_sec = True
        out.append(line)
        continue
    if in_sec and any_sec_re.match(line):
        if not replaced:
            out.append(f"{key} = {value}\n")
            replaced = True
        in_sec = False
    if in_sec and not replaced and key_re.match(line):
        out.append(f"{key} = {value}\n")
        replaced = True
        continue
    out.append(line)

if not replaced:
    if in_sec:
        out.append(f"{key} = {value}\n")
    else:
        if out and not out[-1].endswith("\n"):
            out[-1] += "\n"
        out.append(f"\n[{section}]\n{key} = {value}\n")

path.write_text("".join(out), encoding="utf-8")
PY
}

if [[ "$MODE" == "verify" ]]; then
    echo "=== Bluetooth Hardware & Sleep Status Check ==="
    if [[ -f /etc/modprobe.d/btusb.conf ]]; then
        echo "btusb.conf: installed (/etc/modprobe.d/btusb.conf)"
        grep -q "enable_autosuspend=0" /etc/modprobe.d/btusb.conf && echo "  • USB autosuspend block (enable_autosuspend=0): configured"
        if grep -q "force_scofix=1" /etc/modprobe.d/btusb.conf; then
            echo "  • [WARN] Legacy force_scofix=1 present in btusb.conf (breaks Intel AX211 SCO MTU)"
        fi
    else
        echo "btusb.conf: NOT found in /etc/modprobe.d/"
    fi
    if [[ -d /sys/module/btusb/parameters ]]; then
        echo "btusb live module params: enable_autosuspend=$(cat /sys/module/btusb/parameters/enable_autosuspend 2>/dev/null || echo '?'), force_scofix=$(cat /sys/module/btusb/parameters/force_scofix 2>/dev/null || echo '?'), reset=$(cat /sys/module/btusb/parameters/reset 2>/dev/null || echo '?')"
        if [[ "$(cat /sys/module/btusb/parameters/force_scofix 2>/dev/null || echo 'N')" == "Y" ]]; then
            echo "  • [WARN] Live btusb has force_scofix=Y; reload btusb or reboot after updating btusb.conf"
        fi
    fi
    if [[ -f /etc/udev/rules.d/50-btusb-power.rules ]]; then
        echo "50-btusb-power.rules: installed (/etc/udev/rules.d/50-btusb-power.rules)"
    else
        echo "50-btusb-power.rules: not found in /etc/udev/rules.d/"
    fi
    for dev in /sys/bus/usb/devices/*; do
        if [[ -f "$dev/bDeviceClass" ]] && [[ "$(cat "$dev/bDeviceClass" 2>/dev/null)" == "e0" ]] && [[ "$(cat "$dev/bDeviceSubClass" 2>/dev/null)" == "01" ]] && [[ "$(cat "$dev/bDeviceProtocol" 2>/dev/null)" == "01" ]]; then
            echo "USB BT device $(basename "$dev") ($(cat "$dev/idVendor" 2>/dev/null):$(cat "$dev/idProduct" 2>/dev/null)): power/control=$(cat "$dev/power/control" 2>/dev/null || echo '?')"
        fi
    done
    if [[ -x /usr/lib/systemd/system-sleep/bluetooth-sleep.sh || -x /etc/systemd/system-sleep/bluetooth-sleep.sh ]]; then
        echo "bluetooth-sleep.sh hook: installed and executable"
    else
        echo "bluetooth-sleep.sh hook: not found in system-sleep"
    fi
    if [[ -f /etc/bluetooth/main.conf ]]; then
        echo "main.conf: /etc/bluetooth/main.conf present"
        grep -qi "^[[:space:]]*FastConnectable[[:space:]]*=[[:space:]]*true" /etc/bluetooth/main.conf && echo "  • FastConnectable: active" || echo "  • FastConnectable: not enabled"
        grep -qi "^[[:space:]]*Experimental[[:space:]]*=[[:space:]]*true" /etc/bluetooth/main.conf && echo "  • Battery reporting & D-Bus Experimental: active" || echo "  • Experimental: not enabled"
        grep -qi "^[[:space:]]*MultiProfile[[:space:]]*=[[:space:]]*multiple" /etc/bluetooth/main.conf && echo "  • MultiProfile (A2DP + HFP): active" || echo "  • MultiProfile: not enabled"
        grep -qi "^[[:space:]]*AutoEnable[[:space:]]*=[[:space:]]*true" /etc/bluetooth/main.conf && echo "  • Controller AutoEnable: active" || echo "  • Controller AutoEnable: not enabled"
        grep -qi "^[[:space:]]*ResumeDelay[[:space:]]*=" /etc/bluetooth/main.conf && echo "  • ResumeDelay: configured" || echo "  • ResumeDelay: default (2s)"
    fi
    wp_conf_checked=""
    for wp_conf in /etc/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf "$HOME/.config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf"; do
        if [[ -f "$wp_conf" ]]; then
            wp_conf_checked="$wp_conf"
            echo "wireplumber quality config: active ($wp_conf)"
            if grep -qE '"(hfp_hf|bap_sink|bap_source)"' "$wp_conf"; then
                echo "  • [WARN] $wp_conf still enables hfp_hf/bap_* (may trigger rfcomm_bind or bap errors); re-run setup.sh"
            fi
        fi
    done
    if [[ -z "$wp_conf_checked" ]]; then
        echo "wireplumber quality config: NOT found"
    fi
    echo "bluetooth.service status: $(systemctl is-active bluetooth.service 2>/dev/null || echo 'unknown') (enabled: $(systemctl is-enabled bluetooth.service 2>/dev/null || echo 'unknown'))"
    exit 0
fi

# 1. Install btusb modprobe configuration and USB power udev rule
btusb_changed=0
if [[ -f "$SCRIPT_DIR/btusb.conf" ]]; then
    echo "Installing btusb kernel configuration..."
    if ! cmp -s "$SCRIPT_DIR/btusb.conf" /etc/modprobe.d/btusb.conf 2>/dev/null; then
        btusb_changed=1
    fi
    run_root cp "$SCRIPT_DIR/btusb.conf" /etc/modprobe.d/btusb.conf || true
    run_root chmod 644 /etc/modprobe.d/btusb.conf || true
fi
if [[ -f "$SCRIPT_DIR/50-btusb-power.rules" ]]; then
    echo "Installing btusb USB power control udev rule..."
    run_root mkdir -p /etc/udev/rules.d/ || true
    run_root cp "$SCRIPT_DIR/50-btusb-power.rules" /etc/udev/rules.d/50-btusb-power.rules || true
    run_root chmod 644 /etc/udev/rules.d/50-btusb-power.rules || true
    run_root udevadm control --reload-rules >/dev/null 2>&1 || true
    run_root udevadm trigger --action=add --subsystem-match=usb >/dev/null 2>&1 || true
fi

# 2. Configure BlueZ main.conf (FastConnectable, Battery reporting, AutoEnable, MultiProfile, ResumeDelay)
bluez_restarted=0
if [[ -f "$SCRIPT_DIR/main.conf" ]]; then
    echo "Configuring BlueZ main.conf optimizations..."
    if [[ ! -f /etc/bluetooth/main.conf ]]; then
        run_root mkdir -p /etc/bluetooth || true
        run_root cp "$SCRIPT_DIR/main.conf" /etc/bluetooth/main.conf || true
        run_root chmod 644 /etc/bluetooth/main.conf || true
    elif command -v python3 >/dev/null 2>&1; then
        set_ini_key /etc/bluetooth/main.conf General FastConnectable true || true
        set_ini_key /etc/bluetooth/main.conf General JustWorksRepairing always || true
        set_ini_key /etc/bluetooth/main.conf General Experimental true || true
        set_ini_key /etc/bluetooth/main.conf General MultiProfile multiple || true
        set_ini_key /etc/bluetooth/main.conf Policy AutoEnable true || true
        set_ini_key /etc/bluetooth/main.conf Policy ResumeDelay 3 || true
        set_ini_key /etc/bluetooth/main.conf Policy ReconnectAttempts 7 || true
        set_ini_key /etc/bluetooth/main.conf Policy ReconnectIntervals "1, 2, 4, 8, 16, 32, 64" || true
    else
        run_root sed -i 's|^#*[[:space:]]*FastConnectable[[:space:]]*=.*|FastConnectable = true|' /etc/bluetooth/main.conf || true
        run_root sed -i 's|^#*[[:space:]]*JustWorksRepairing[[:space:]]*=.*|JustWorksRepairing = always|' /etc/bluetooth/main.conf || true
        run_root sed -i 's|^#*[[:space:]]*Experimental[[:space:]]*=.*|Experimental = true|' /etc/bluetooth/main.conf || true
        run_root sed -i 's|^#*[[:space:]]*MultiProfile[[:space:]]*=.*|MultiProfile = multiple|' /etc/bluetooth/main.conf || true
        run_root sed -i 's|^#*[[:space:]]*AutoEnable[[:space:]]*=.*|AutoEnable = true|' /etc/bluetooth/main.conf || true
        run_root sed -i 's|^#*[[:space:]]*ResumeDelay[[:space:]]*=.*|ResumeDelay = 3|' /etc/bluetooth/main.conf || true
        run_root sed -i 's|^#*[[:space:]]*ReconnectAttempts[[:space:]]*=.*|ReconnectAttempts = 7|' /etc/bluetooth/main.conf || true
        run_root sed -i 's|^#*[[:space:]]*ReconnectIntervals[[:space:]]*=.*|ReconnectIntervals = 1, 2, 4, 8, 16, 32, 64|' /etc/bluetooth/main.conf || true
    fi
fi

# 3. Reload btusb cleanly if parameters changed, then restart bluetooth.service
live_scofix="$(cat /sys/module/btusb/parameters/force_scofix 2>/dev/null || echo 'N')"
if [[ $btusb_changed -eq 1 || "$live_scofix" == "Y" ]]; then
    if lsmod 2>/dev/null | grep -q '^btusb'; then
        echo "Reloading btusb kernel module to apply updated parameters..."
        run_root systemctl stop bluetooth.service 2>/dev/null || true
        if run_root modprobe -r btusb 2>/dev/null && run_root modprobe btusb 2>/dev/null; then
            echo "btusb reloaded with updated parameters."
        else
            echo -e "\033[1;33m[WARN]\033[0m Could not unload btusb live; reboot required to apply btusb.conf." >&2
        fi
        run_root systemctl start bluetooth.service 2>/dev/null || true
        bluez_restarted=1
    fi
fi

if [[ $bluez_restarted -eq 0 ]] && command -v systemctl >/dev/null 2>&1; then
    run_root systemctl try-restart bluetooth.service 2>/dev/null || true
    bluez_restarted=1
fi

# 4. Install bluetooth sleep hook
if [[ -f "$SCRIPT_DIR/bluetooth-sleep.sh" ]]; then
    echo "Installing bluetooth-sleep hook to $HOOK_DEST..."
    run_root mkdir -p "$HOOK_DEST" || true
    run_root cp "$SCRIPT_DIR/bluetooth-sleep.sh" "$HOOK_DEST/bluetooth-sleep.sh" || true
    run_root chmod +x "$HOOK_DEST/bluetooth-sleep.sh" || true
    if command -v restorecon >/dev/null 2>&1; then
        run_root restorecon "$HOOK_DEST/bluetooth-sleep.sh" 2>/dev/null || true
    fi
fi

# 5. Install WirePlumber quality configuration (system-wide and user-specific)
WP_CONF_SRC="$REPO_DIR/core/config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf"
if [[ -f "$WP_CONF_SRC" ]]; then
    echo "Installing WirePlumber quality configuration..."
    run_root mkdir -p /etc/wireplumber/wireplumber.conf.d/ || true
    run_root cp "$WP_CONF_SRC" /etc/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf || true
    run_root chmod 644 /etc/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf || true

    target_user="${SUDO_USER:-${USER:-$(id -un)}}"
    user_home="$(getent passwd "$target_user" 2>/dev/null | cut -d: -f6 || echo "${HOME:-}")"
    if [[ -n "$user_home" && -d "$user_home" && "$target_user" != "root" ]]; then
        user_wp_dir="$user_home/.config/wireplumber/wireplumber.conf.d"
        user_wp_conf="$user_wp_dir/50-bluetooth-quality.conf"
        # Skip symlinking if sync.sh already linked ~/.config/wireplumber -> core/config/wireplumber
        if [[ ! "$WP_CONF_SRC" -ef "$user_wp_conf" ]]; then
            if [[ "$(id -u)" -eq 0 ]]; then
                sudo -u "$target_user" mkdir -p "$user_wp_dir" 2>/dev/null || true
                sudo -u "$target_user" ln -sf "$WP_CONF_SRC" "$user_wp_conf" 2>/dev/null || true
            else
                mkdir -p "$user_wp_dir"
                ln -sf "$WP_CONF_SRC" "$user_wp_conf"
            fi
        fi
    fi
fi

# 6. Always restart user audio stack after bluetoothd/WirePlumber changes to prevent
#    spa.bluez5 RFCOMM/GATT socket collisions (Address already in use / deadlock)
if [[ $bluez_restarted -eq 1 || -f "$WP_CONF_SRC" ]]; then
    restart_user_audio
fi

if [[ $btusb_changed -eq 1 ]] && command -v dracut >/dev/null 2>&1; then
    echo "Note: On Fedora/dracut systems, consider running 'sudo dracut --regenerate-all --force' or rebooting if early initramfs embeds /etc/modprobe.d/btusb.conf."
fi

echo "Bluetooth hardware configuration and audio autoswitch installed successfully."
