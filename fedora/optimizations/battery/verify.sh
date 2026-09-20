#!/usr/bin/env bash
# ==============================================================================
# Battery Charging Limit Verification
# ==============================================================================
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

echo -e "\n${BOLD}=== Battery Charging Limit Status Check ===${NC}\n"

# 1. Check ASUS ROG / TUF management
if command -v asusctl >/dev/null 2>&1; then
    asus_info=$(asusctl battery info 2>/dev/null || true)
    if [[ -n "$asus_info" ]]; then
        log_success "ASUS ROG daemon (asusd) active: ${BOLD}$asus_info${NC}"
    fi
    if [[ -f /etc/asusd/asusd.ron ]]; then
        ron_limit=$(grep -E 'charge_control_end_threshold:' /etc/asusd/asusd.ron | head -n 1 | awk '{print $2}' | tr -d ',' || true)
        log_info "Configured in /etc/asusd/asusd.ron: ${BOLD}${ron_limit:-unknown}%${NC}"
    fi
fi

# 2. Check kernel sysfs nodes
SYSFS_NODES=()
for pattern in /sys/class/power_supply/*/charge_control_end_threshold /sys/class/power_supply/*/charge_stop_threshold; do
    for node in $pattern; do
        [[ -f "$node" ]] && SYSFS_NODES+=("$node")
    done
done

if [[ ${#SYSFS_NODES[@]} -gt 0 ]]; then
    for node in "${SYSFS_NODES[@]}"; do
        curr=$(cat "$node" 2>/dev/null || echo "unreadable")
        if [[ "$curr" -le 85 && "$curr" -ge 40 ]]; then
            log_success "Sysfs threshold at $node: ${BOLD}${curr}%${NC}"
        else
            log_warn "Sysfs threshold at $node: ${BOLD}${curr}%${NC}"
        fi
    done
else
    log_warn "No battery charging threshold sysfs nodes detected."
fi

# 3. Check battery status & capacity
for bat in /sys/class/power_supply/BAT*; do
    if [[ -d "$bat" ]]; then
        name=$(basename "$bat")
        status=$(cat "$bat/status" 2>/dev/null || echo "unknown")
        capacity=$(cat "$bat/capacity" 2>/dev/null || echo "unknown")
        log_info "Battery [${name}]: Status=${BOLD}${status}${NC}, Current Capacity=${BOLD}${capacity}%${NC}"
    fi
done

# 4. Check systemd service and hooks
echo ""
log_info "Checking systemd service and hooks:"
SERVICE="battery-limit.service"
state=$(systemctl is-enabled "$SERVICE" 2>/dev/null) || state="${state:-not-found}"
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
