#!/usr/bin/env bash
# ==============================================================================
# Battery Charging Limit Installer (85% Health Cap)
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

BIN_DEST="${1:-/usr/local/bin}"
SERVICE_DEST="${2:-/etc/systemd/system}"

log_info "Configuring Battery Charging Limit (85% cap)..."

# 1. Hardware check: verify if battery charge threshold is supported
BATTERY_NODES=()
for pattern in /sys/class/power_supply/*/charge_control_end_threshold /sys/class/power_supply/*/charge_stop_threshold; do
    for node in $pattern; do
        [[ -f "$node" ]] && BATTERY_NODES+=("$node")
    done
done

if [[ ${#BATTERY_NODES[@]} -eq 0 ]] && ! command -v asusctl >/dev/null 2>&1; then
    log_warn "No supported battery charging threshold found (desktop, VM, or unsupported hardware). Skipping."
    exit 0
fi

if command -v asusctl >/dev/null 2>&1; then
    log_info "Detected ASUS ROG/TUF hardware management (asusctl/asusd)."
fi
if [[ ${#BATTERY_NODES[@]} -gt 0 ]]; then
    log_info "Detected battery threshold node(s): ${BATTERY_NODES[*]}"
fi

# Check if running with root privileges or passwordless sudo
has_root=0
if [[ "$(id -u)" -eq 0 ]]; then
    has_root=1
elif sudo -n true 2>/dev/null; then
    has_root=1
fi

if [[ $has_root -eq 1 ]]; then
    # 2. Install executable script to BIN_DEST
    run_as_root mkdir -p "$BIN_DEST" "$SERVICE_DEST"
    run_as_root cp "$SCRIPT_DIR/set-battery-limit.sh" "$BIN_DEST/set-battery-limit.sh"
    run_as_root chmod 755 "$BIN_DEST/set-battery-limit.sh"
    log_success "Installed executable: $BIN_DEST/set-battery-limit.sh"

    # 3. Install systemd service unit
    SERVICE_NAME="battery-limit.service"
    TARGET_SERVICE="$SERVICE_DEST/$SERVICE_NAME"
    sed "s|/usr/local/bin/set-battery-limit.sh|$BIN_DEST/set-battery-limit.sh|g" "$SCRIPT_DIR/$SERVICE_NAME" | run_as_root tee "$TARGET_SERVICE" >/dev/null
    run_as_root chmod 644 "$TARGET_SERVICE"
    log_success "Installed systemd unit: $TARGET_SERVICE"

    # 4. Install udev rule so limit is re-asserted whenever power adapter connects/disconnects
    UDEV_RULE="/etc/udev/rules.d/90-battery-limit.rules"
    echo "SUBSYSTEM==\"power_supply\", ACTION==\"change\", RUN+=\"$BIN_DEST/set-battery-limit.sh\"" | run_as_root tee "$UDEV_RULE" >/dev/null
    run_as_root chmod 644 "$UDEV_RULE"
    run_as_root udevadm control --reload 2>/dev/null || true
    log_success "Installed udev rule: $UDEV_RULE"

    # 5. Install systemd-sleep hook so limit is re-asserted on resume from sleep/hibernate
    SLEEP_DIR="/usr/lib/systemd/system-sleep"
    if [[ -d "$SLEEP_DIR" ]]; then
        SLEEP_HOOK="$SLEEP_DIR/set-battery-limit.sh"
        printf '#!/bin/sh\nexec %s "$@"\n' "$BIN_DEST/set-battery-limit.sh" | run_as_root tee "$SLEEP_HOOK" >/dev/null
        run_as_root chmod 755 "$SLEEP_HOOK"
        log_success "Installed system-sleep hook: $SLEEP_HOOK"
    fi

    # 6. Reload systemd daemon, enable and start service
    log_info "Reloading systemd daemon..."
    run_as_root systemctl daemon-reload

    log_info "Enabling and starting service: $SERVICE_NAME"
    run_as_root systemctl enable --now "$SERVICE_NAME"

    # 7. Run immediately to apply threshold
    log_info "Applying battery charging limit immediately..."
    run_as_root "$BIN_DEST/set-battery-limit.sh"
else
    log_warn "Running without root privileges; system service and udev rule installation skipped."
    log_info "Applying battery limit directly..."
    bash "$SCRIPT_DIR/set-battery-limit.sh"
    log_info "To install the persistent system-wide systemd service and udev rules, run: sudo ./install.sh"
fi

log_success "Battery limit optimization configured successfully (85% cap, persistent across sleep/reboot/AC connect)!"
