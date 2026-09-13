#!/usr/bin/env bash
# ==============================================================================
# Disable USB and peripheral ACPI wake triggers (Prevents backpack wake-ups)
# ==============================================================================
set -e

if [[ -f /proc/acpi/wakeup ]]; then
    awk '/\*enabled/ {print $1}' /proc/acpi/wakeup | while read -r device; do
        # Retain power button (PWRB) and sleep button (SLPB)
        if [[ "$device" != "PWRB" && "$device" != "SLPB" ]]; then
            echo "$device" > /proc/acpi/wakeup || true
        fi
    done
fi
