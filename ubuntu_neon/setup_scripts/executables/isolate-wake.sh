#!/bin/bash

# Find all currently enabled ACPI wake triggers
awk '/\*enabled/ {print $1}' /proc/acpi/wakeup | while read -r device; do
    # Ignore the Power Button (PWRB) and Sleep Button (SLPB)
    if [ "$device" != "PWRB" ] && [ "$device" != "SLPB" ]; then
        # Toggle the enabled device off
        echo "$device" >/proc/acpi/wakeup
    fi
done
