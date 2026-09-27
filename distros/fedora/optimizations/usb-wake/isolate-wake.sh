#!/usr/bin/env bash
# ==============================================================================
# Disable USB Wake (Hot Backpack Fix)
# Only disables USB wake controllers and devices. Never touches PCIe, GPU, or buttons.
# ==============================================================================
set -euo pipefail

# 1. Disable USB controllers in /proc/acpi/wakeup (only if currently enabled, since ACPI is a toggle)
if [[ -f /proc/acpi/wakeup ]]; then
    while read -r dev _ status rest; do
        if [[ "$dev" =~ ^XHC|^USB|^EHC ]] && [[ "$status" == "*enabled" ]]; then
            echo "$dev" > /proc/acpi/wakeup 2>/dev/null || true
        fi
    done < /proc/acpi/wakeup
fi

# 2. Disable wakeup on USB devices and root hubs
for dev in /sys/bus/usb/devices/*/power/wakeup; do
    if [[ -f "$dev" ]]; then
        echo "disabled" > "$dev" 2>/dev/null || true
    fi
done
