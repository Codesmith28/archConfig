#!/usr/bin/env bash
# ==============================================================================
# Battery Charging Limit & Deep Sleep Setup (85% Health Cap + S3 Suspend)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
else
    log_info()    { echo "[INFO] $*"; }
    log_success() { echo "[OK]   $*"; }
    log_warn()    { echo "[WARN] $*" >&2; }
    log_error()   { echo "[ERR]  $*" >&2; }
    run_as_root() {
        if [[ "$(id -u)" -eq 0 ]]; then
            "$@"
        elif command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            log_error "Root privileges required. Please run with sudo or as root."
            exit 1
        fi
    }
fi

# Verification function
verify_battery_and_sleep() {
    echo -e "\n${BOLD}=== Battery & Deep Sleep Status Check ===${NC}\n"

    # 1. ASUS ROG / TUF management
    if command -v asusctl >/dev/null 2>&1; then
        asus_info=$(asusctl battery info 2>/dev/null || true)
        if [[ -n "$asus_info" ]]; then
            log_success "ASUS ROG daemon (asusd) active: ${BOLD}$asus_info${NC}"
        fi
        if [[ -f /etc/asusd/asusd.ron ]]; then
            ron_limit=$(grep -E 'charge_control_end_threshold:' /etc/asusd/asusd.ron 2>/dev/null | head -n 1 | awk '{print $2}' | tr -d ',' || true)
            log_info "Configured in /etc/asusd/asusd.ron: ${BOLD}${ron_limit:-unknown}%${NC}"
        fi
    fi

    # 2. Kernel sysfs battery nodes
    SYSFS_NODES=()
    for pattern in /sys/class/power_supply/*/charge_control_end_threshold /sys/class/power_supply/*/charge_stop_threshold; do
        for node in $pattern; do
            [[ -f "$node" ]] && SYSFS_NODES+=("$node")
        done
    done

    if [[ ${#SYSFS_NODES[@]} -gt 0 ]]; then
        for node in "${SYSFS_NODES[@]}"; do
            curr=$(cat "$node" 2>/dev/null || echo "unreadable")
            if [[ "$curr" =~ ^[0-9]+$ ]] && [[ "$curr" -le 85 && "$curr" -ge 40 ]]; then
                log_success "Sysfs threshold at $node: ${BOLD}${curr}%${NC}"
            else
                log_warn "Sysfs threshold at $node: ${BOLD}${curr}%${NC}"
            fi
        done
    else
        log_info "No sysfs charging threshold nodes found (desktop, VM, or proprietary driver)."
    fi

    # 3. Battery status & capacity
    for bat in /sys/class/power_supply/BAT*; do
        if [[ -d "$bat" ]]; then
            name=$(basename "$bat")
            status=$(cat "$bat/status" 2>/dev/null || echo "unknown")
            capacity=$(cat "$bat/capacity" 2>/dev/null || echo "unknown")
            log_info "Battery [${name}]: Status=${BOLD}${status}${NC}, Current Capacity=${BOLD}${capacity}%${NC}"
        fi
    done

    # 4. Deep Sleep Verification
    echo ""
    log_info "Checking Sleep / Suspend Mode:"
    if [[ -f /sys/power/mem_sleep ]]; then
        mem_sleep_content=$(cat /sys/power/mem_sleep 2>/dev/null || echo "unknown")
        active_mode=$(grep -o '\[.*\]' /sys/power/mem_sleep 2>/dev/null | tr -d '[]' || echo "unknown")
        if [[ "$active_mode" == "deep" ]]; then
            log_success "Active kernel mem_sleep: ${BOLD}${active_mode}${NC} (Modes: ${mem_sleep_content})"
        else
            log_warn "Active kernel mem_sleep: ${BOLD}${active_mode}${NC} (Modes: ${mem_sleep_content})"
        fi
    fi

    if [[ -f /etc/tmpfiles.d/deep-sleep.conf ]]; then
        log_success "tmpfiles.d deep-sleep config: ${BOLD}$(cat /etc/tmpfiles.d/deep-sleep.conf 2>/dev/null | tr -d '\n')${NC}"
    else
        log_warn "tmpfiles.d deep-sleep config NOT found at /etc/tmpfiles.d/deep-sleep.conf"
    fi

    if [[ -f /etc/systemd/sleep.conf.d/deep-sleep.conf ]]; then
        log_success "systemd sleep.conf.d deep-sleep config installed at /etc/systemd/sleep.conf.d/deep-sleep.conf"
    else
        log_warn "systemd sleep.conf.d deep-sleep config NOT found"
    fi

    # Check kernel command line
    if grep -q "mem_sleep_default=deep" /proc/cmdline 2>/dev/null; then
        log_success "Current boot cmdline: ${BOLD}mem_sleep_default=deep${NC} active"
    else
        log_info "Kernel cmdline: ${BOLD}mem_sleep_default=deep${NC} configured via grubby (active on reboot)"
    fi

    # 5. Systemd service, udev rule, and sleep hook
    echo ""
    log_info "Checking systemd service and hooks:"
    SERVICE="battery-limit.service"
    state=$(systemctl is-enabled "$SERVICE" 2>/dev/null || true)
    state="${state:-not-found}"
    if [[ "$state" == "enabled" ]]; then
        log_success "Systemd unit $SERVICE: ${BOLD}$state${NC}"
    else
        log_warn "Systemd unit $SERVICE: ${BOLD}$state${NC}"
    fi

    UDEV_RULE="/etc/udev/rules.d/90-battery-limit.rules"
    if [[ -f "$UDEV_RULE" ]]; then
        log_success "Udev rule installed: $UDEV_RULE"
    else
        log_warn "Udev rule NOT found at $UDEV_RULE"
    fi

    SLEEP_HOOK="/usr/lib/systemd/system-sleep/set-battery-limit.sh"
    if [[ -f "$SLEEP_HOOK" ]]; then
        log_success "System-sleep hook installed: $SLEEP_HOOK"
    else
        log_warn "System-sleep hook NOT found at $SLEEP_HOOK"
    fi

    echo ""
}

# Check for verify flag
if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    verify_battery_and_sleep
    exit 0
fi

BIN_DEST="${1:-/usr/local/bin}"
SERVICE_DEST="${2:-/etc/systemd/system}"

log_info "Configuring Battery Charging Limit (85% cap) & Deep Sleep (S3)..."

# Check hardware support
BATTERY_NODES=()
for pattern in /sys/class/power_supply/*/charge_control_end_threshold /sys/class/power_supply/*/charge_stop_threshold; do
    for node in $pattern; do
        [[ -f "$node" ]] && BATTERY_NODES+=("$node")
    done
done

has_battery_mgmt=0
if [[ ${#BATTERY_NODES[@]} -gt 0 ]] || command -v asusctl >/dev/null 2>&1; then
    has_battery_mgmt=1
fi

has_deep_sleep=0
if [[ -f /sys/power/mem_sleep ]] && grep -q "deep" /sys/power/mem_sleep; then
    has_deep_sleep=1
fi

if [[ $has_battery_mgmt -eq 0 && $has_deep_sleep -eq 0 ]]; then
    log_warn "Neither battery charge threshold nor deep sleep supported on this system. Skipping."
    exit 0
fi

if command -v asusctl >/dev/null 2>&1; then
    log_info "Detected ASUS ROG/TUF hardware management (asusctl/asusd)."
fi
if [[ ${#BATTERY_NODES[@]} -gt 0 ]]; then
    log_info "Detected battery threshold node(s): ${BATTERY_NODES[*]}"
fi
if [[ $has_deep_sleep -eq 1 ]]; then
    curr_mem_sleep=$(grep -o '\[.*\]' /sys/power/mem_sleep 2>/dev/null | tr -d '[]' || echo "unknown")
    log_info "Detected sleep state support: /sys/power/mem_sleep has 'deep' (current: ${BOLD}${curr_mem_sleep}${NC})"
fi

# Check if running with root privileges or passwordless sudo
has_root=0
if [[ "$(id -u)" -eq 0 ]]; then
    has_root=1
elif sudo -n true 2>/dev/null; then
    has_root=1
fi

if [[ $has_root -eq 1 ]]; then
    # 1. Install executable script to BIN_DEST
    run_as_root mkdir -p "$BIN_DEST" "$SERVICE_DEST"
    run_as_root cp "$SCRIPT_DIR/set-battery-limit.sh" "$BIN_DEST/set-battery-limit.sh"
    run_as_root chmod 755 "$BIN_DEST/set-battery-limit.sh"
    log_success "Installed executable: $BIN_DEST/set-battery-limit.sh"

    # 2. Install systemd service unit
    SERVICE_NAME="battery-limit.service"
    TARGET_SERVICE="$SERVICE_DEST/$SERVICE_NAME"
    sed "s|/usr/local/bin/set-battery-limit.sh|$BIN_DEST/set-battery-limit.sh|g" "$SCRIPT_DIR/$SERVICE_NAME" | run_as_root tee "$TARGET_SERVICE" >/dev/null
    run_as_root chmod 644 "$TARGET_SERVICE"
    log_success "Installed systemd unit: $TARGET_SERVICE"

    # 3. Install udev rule so limit is re-asserted whenever power adapter connects/disconnects
    UDEV_RULE="/etc/udev/rules.d/90-battery-limit.rules"
    echo "SUBSYSTEM==\"power_supply\", ACTION==\"change\", RUN+=\"$BIN_DEST/set-battery-limit.sh\"" | run_as_root tee "$UDEV_RULE" >/dev/null
    run_as_root chmod 644 "$UDEV_RULE"
    run_as_root udevadm control --reload 2>/dev/null || true
    log_success "Installed udev rule: $UDEV_RULE"

    # 4. Install systemd-sleep hook so limit & deep sleep are re-asserted on resume from sleep/hibernate
    SLEEP_DIR="/usr/lib/systemd/system-sleep"
    if [[ -d "$SLEEP_DIR" ]]; then
        SLEEP_HOOK="$SLEEP_DIR/set-battery-limit.sh"
        printf '#!/bin/sh\nexec %s "$@"\n' "$BIN_DEST/set-battery-limit.sh" | run_as_root tee "$SLEEP_HOOK" >/dev/null
        run_as_root chmod 755 "$SLEEP_HOOK"
        log_success "Installed system-sleep hook: $SLEEP_HOOK"
    fi

    # 5. Persist Deep Sleep (S3 Suspend-to-RAM) from s2idle
    if [[ $has_deep_sleep -eq 1 ]]; then
        log_info "Configuring deep sleep persistence..."

        # 5a. systemd-tmpfiles: write deep to /sys/power/mem_sleep at boot
        run_as_root mkdir -p /etc/tmpfiles.d
        echo "w /sys/power/mem_sleep - - - - deep" | run_as_root tee /etc/tmpfiles.d/deep-sleep.conf >/dev/null
        run_as_root chmod 644 /etc/tmpfiles.d/deep-sleep.conf
        log_success "Configured tmpfiles.d deep sleep: /etc/tmpfiles.d/deep-sleep.conf"

        # 5b. systemd sleep configuration drop-in: MemorySleepMode=deep
        run_as_root mkdir -p /etc/systemd/sleep.conf.d
        cat << 'EOF' | run_as_root tee /etc/systemd/sleep.conf.d/deep-sleep.conf >/dev/null
[Sleep]
MemorySleepMode=deep
EOF
        run_as_root chmod 644 /etc/systemd/sleep.conf.d/deep-sleep.conf
        log_success "Configured systemd sleep mode: /etc/systemd/sleep.conf.d/deep-sleep.conf"

        # 5c. Kernel parameter persistence via grubby (Fedora BLS)
        if command -v grubby >/dev/null 2>&1; then
            if run_as_root grubby --update-kernel=ALL --args="mem_sleep_default=deep" 2>/dev/null; then
                log_success "Added 'mem_sleep_default=deep' to all kernels via grubby."
            fi
        fi

        # 5d. Apply immediately to active kernel session
        if [[ -w /sys/power/mem_sleep || "$(id -u)" -eq 0 ]]; then
            echo "deep" > /sys/power/mem_sleep 2>/dev/null || true
        else
            echo "deep" | run_as_root tee /sys/power/mem_sleep >/dev/null 2>&1 || true
        fi
        current_sleep=$(grep -o '\[.*\]' /sys/power/mem_sleep 2>/dev/null | tr -d '[]' || echo "unknown")
        log_success "Applied deep sleep mode immediately (active: ${BOLD}${current_sleep}${NC})"
    fi

    # 6. Reload systemd daemon, enable and start service
    log_info "Reloading systemd daemon..."
    run_as_root systemctl daemon-reload

    log_info "Enabling and starting service: $SERVICE_NAME"
    run_as_root systemctl enable --now "$SERVICE_NAME"

    # 7. Run immediately to apply threshold and sleep settings
    log_info "Applying optimizations immediately..."
    run_as_root "$BIN_DEST/set-battery-limit.sh"

    # 8. Run verification
    verify_battery_and_sleep
else
    log_warn "Running without root privileges; system service, udev rule, and persistent boot config skipped."
    log_info "Applying battery and sleep settings directly for current session..."
    bash "$SCRIPT_DIR/set-battery-limit.sh"
    log_info "To install persistent system-wide systemd services, udev rules, and boot configs, run: sudo ./setup.sh"
fi

log_success "Battery limit & deep sleep optimizations configured successfully!"
