#!/usr/bin/env bash
# ==============================================================================
# USB Wake Isolation Setup (Hot Backpack Fix + Working Keyboard Wake)
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

verify_wake() {
    log_info "Current Wakeup Status Verification:"
    if [[ -f /proc/acpi/wakeup ]]; then
        xhci_acpi=$(awk '$1 ~ /^XHC/ {for(i=1; i<=NF; i++) if ($i ~ /^\*(enabled|disabled)$/) print $1 ": " $i}' /proc/acpi/wakeup || true)
        log_info "  ACPI: ${xhci_acpi:-none}"
    fi

    for pci_dev in /sys/bus/pci/drivers/xhci_hcd/*; do
        if [[ -f "$pci_dev/power/wakeup" ]]; then
            log_info "  PCI Host: $(basename "$pci_dev") -> $(cat "$pci_dev/power/wakeup")"
        fi
    done

    for root_hub in /sys/bus/usb/devices/usb*; do
        if [[ -f "$root_hub/power/wakeup" ]]; then
            log_info "  Root Hub: $(basename "$root_hub") -> $(cat "$root_hub/power/wakeup")"
        fi
    done

    for dev in /sys/bus/usb/devices/*; do
        if [[ -f "$dev/power/wakeup" && ! "$dev" =~ /usb[0-9]+$ ]]; then
            prod=$(cat "$dev/product" 2>/dev/null || echo "")
            status=$(cat "$dev/power/wakeup")
            if [[ -n "$prod" ]]; then
                log_info "  USB Device: $(basename "$dev") ($prod) -> $status"
            fi
        fi
    done
}

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    verify_wake
    exit 0
fi

BIN_DEST="${1:-/usr/local/bin}"
SERVICE_DEST="${2:-/etc/systemd/system}"

log_info "Configuring USB wake isolation (working keyboard wake + hot backpack fix)..."

# 1. Install executable isolate-wake.sh
run_as_root mkdir -p "$BIN_DEST" "$SERVICE_DEST"
run_as_root cp "$SCRIPT_DIR/isolate-wake.sh" "$BIN_DEST/isolate-wake.sh"
run_as_root chmod 755 "$BIN_DEST/isolate-wake.sh"
log_success "Installed executable: $BIN_DEST/isolate-wake.sh"

# 2. Install systemd service unit
SERVICE_NAME="disable-xhci-wake.service"
TARGET_SERVICE="$SERVICE_DEST/$SERVICE_NAME"
sed "s|/usr/local/bin/isolate-wake.sh|$BIN_DEST/isolate-wake.sh|g" "$SCRIPT_DIR/$SERVICE_NAME" | run_as_root tee "$TARGET_SERVICE" >/dev/null
run_as_root chmod 644 "$TARGET_SERVICE"
log_success "Installed systemd unit: $TARGET_SERVICE"

# 3. Install udev rule for dynamic USB device plug/unplug events
UDEV_RULE="/etc/udev/rules.d/90-usb-wake-isolate.rules"
echo "ACTION==\"add\", SUBSYSTEM==\"usb\", DEVTYPE==\"usb_device\", RUN+=\"$BIN_DEST/isolate-wake.sh\"" | run_as_root tee "$UDEV_RULE" >/dev/null
run_as_root chmod 644 "$UDEV_RULE"
run_as_root udevadm control --reload 2>/dev/null || true
log_success "Installed udev rule: $UDEV_RULE"

# 4. Install systemd-sleep hook so policy is enforced right before suspend
SLEEP_DIR="/usr/lib/systemd/system-sleep"
if [[ -d "$SLEEP_DIR" ]]; then
    SLEEP_HOOK="$SLEEP_DIR/isolate-wake.sh"
    printf '#!/bin/sh\nexec %s "$@"\n' "$BIN_DEST/isolate-wake.sh" | run_as_root tee "$SLEEP_HOOK" >/dev/null
    run_as_root chmod 755 "$SLEEP_HOOK"
    log_success "Installed system-sleep hook: $SLEEP_HOOK"
fi

# 5. Reload systemd and enable/restart the service
log_info "Reloading systemd daemon..."
run_as_root systemctl daemon-reload

log_info "Enabling and restarting service: $SERVICE_NAME"
run_as_root systemctl enable "$SERVICE_NAME"
run_as_root systemctl restart "$SERVICE_NAME"

# 6. Apply wake isolation to the current running session immediately
log_info "Applying wake isolation settings immediately..."
run_as_root "$BIN_DEST/isolate-wake.sh"

# 7. Verification check
verify_wake

log_success "USB wake isolation configured and verified successfully!"
