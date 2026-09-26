#!/usr/bin/env bash
# ==============================================================================
# USB & ACPI Wake Isolation (Hot Backpack Fix + Working Keyboard Wake)
# ==============================================================================
# Ensures keyboard keys (internal ASUS keyboard & external USB keyboards)
# can wake the machine from sleep, while isolating and disabling unwanted wakeups
# (USB mice, touchpads, webcams, Bluetooth, network wake) that cause "hot backpack"
# battery drain and overheating issues.
# ==============================================================================
set -euo pipefail

# If invoked by systemd-sleep hook ($1 = pre|post), only run on suspend preparation
if [[ "${1:-}" == "post" ]]; then
    exit 0
fi

# ------------------------------------------------------------------------------
# 1. ACPI Wakeup Management (/proc/acpi/wakeup)
# ------------------------------------------------------------------------------
get_acpi_status() {
    local target="$1"
    awk -v dev="$target" '$1 == dev {for(i=1; i<=NF; i++) if ($i ~ /^\*(enabled|disabled)$/) {sub(/^\*/, "", $i); print $i; exit}}' /proc/acpi/wakeup 2>/dev/null || true
}

set_acpi_status() {
    local target="$1"
    local desired="$2" # "enabled" or "disabled"
    local curr
    curr=$(get_acpi_status "$target")
    if [[ -n "$curr" && "$curr" != "$desired" ]]; then
        echo "$target" > /proc/acpi/wakeup 2>/dev/null || true
    fi
}

if [[ -f /proc/acpi/wakeup ]]; then
    declare -A seen_acpi=()
    while read -r name sstate status rest; do
        [[ "$name" =~ ^Device || -z "$name" ]] && continue
        [[ ! "$name" =~ ^[A-Za-z0-9_]+$ ]] && continue

        # Avoid toggling duplicate ACPI entries repeatedly (e.g. multiple PXSX lines)
        if [[ -n "${seen_acpi[$name]:-}" ]]; then
            continue
        fi
        seen_acpi["$name"]=1

        case "$name" in
            XHCI|XHC*|USB*|PWRB|SLPB|LID*|PBTN|SBTN)
                # Keep essential wake triggers enabled (Keyboards on USB, Power/Sleep buttons, Lid)
                set_acpi_status "$name" "enabled"
                ;;
            CNVW|WLAN|WL*|XDCI|HDAS|HDEF|AUDIO|AWAC|RTC|PEG*|RP*|GLAN|LAN|GBE)
                # Disable network, audio, RTC, and PCIe bus wakeups to avoid backpack wakeups
                set_acpi_status "$name" "disabled"
                ;;
            *)
                # Disable other non-essential wake triggers
                set_acpi_status "$name" "disabled"
                ;;
        esac
    done < /proc/acpi/wakeup

    # Explicitly enforce XHCI is enabled so USB keyboards can wake the system
    set_acpi_status "XHCI" "enabled"
fi

# ------------------------------------------------------------------------------
# 2. Host Controllers & Root Hubs
# ------------------------------------------------------------------------------
# Enable wakeup on all XHCI / USB PCI host controllers
for pci_dev in /sys/bus/pci/drivers/*hci*/*; do
    if [[ -f "$pci_dev/power/wakeup" ]]; then
        echo "enabled" > "$pci_dev/power/wakeup" 2>/dev/null || true
    fi
done

# Enable wakeup on USB root hubs so keyboard wake signals can reach the kernel
for root_hub in /sys/bus/usb/devices/usb*; do
    if [[ -f "$root_hub/power/wakeup" ]]; then
        echo "enabled" > "$root_hub/power/wakeup" 2>/dev/null || true
    fi
done

# Ensure PS/2 / AT keyboard wakeup is enabled if present
for i8042_dev in /sys/devices/platform/i8042/*/power/wakeup; do
    if [[ -f "$i8042_dev" ]]; then
        echo "enabled" > "$i8042_dev" 2>/dev/null || true
    fi
done

# ------------------------------------------------------------------------------
# 3. Granular USB Peripheral Wake Isolation
# ------------------------------------------------------------------------------
# Iterate through all connected USB devices:
# - Enable wakeup for keyboards (internal ASUS N-KEY device and external USB keyboards)
# - Enable wakeup for USB hubs/docks (so downstream keyboards can wake through them)
# - Disable wakeup for mice, touchpads, webcams, Bluetooth to prevent accidental backpack wakeups
for dev in /sys/bus/usb/devices/*; do
    [ -f "$dev/power/wakeup" ] || continue
    # Skip USB root hubs (handled above)
    [[ "$dev" =~ /usb[0-9]+$ ]] && continue

    # Allow USB hubs to forward wake events from downstream keyboards
    dev_cls=$(cat "$dev/bDeviceClass" 2>/dev/null || echo "")
    if [[ "$dev_cls" == "09" ]]; then
        echo "enabled" > "$dev/power/wakeup" 2>/dev/null || true
        continue
    fi

    is_keyboard=0
    is_mouse=0

    # 1. Inspect USB HID interfaces
    for intf in "$dev"/*:*; do
        [ -d "$intf" ] || continue
        cls=$(cat "$intf/bInterfaceClass" 2>/dev/null || true)
        proto=$(cat "$intf/bInterfaceProtocol" 2>/dev/null || true)
        if [[ "$cls" == "03" ]]; then
            if [[ "$proto" == "01" ]]; then
                is_keyboard=1
            elif [[ "$proto" == "02" ]]; then
                is_mouse=1
            fi
        elif [[ "$cls" == "09" ]]; then
            # Interface-level hub
            echo "enabled" > "$dev/power/wakeup" 2>/dev/null || true
            continue 2
        fi
    done

    # 2. Inspect product and manufacturer strings
    prod=$(cat "$dev/product" 2>/dev/null || echo "")
    manuf=$(cat "$dev/manufacturer" 2>/dev/null || echo "")

    if [[ "$prod" =~ [Kk]eyboard|[Kk]ey|N-KEY || "$manuf" =~ [Kk]eyboard ]]; then
        is_keyboard=1
    fi

    # Explicitly flag mice
    if [[ "$prod" =~ [Mm]ouse|[Tt]rackball ]]; then
        is_mouse=1
    fi

    # 3. Apply wake policy
    if [[ $is_keyboard -eq 1 && $is_mouse -eq 0 ]]; then
        # Pure keyboard: allow wake
        echo "enabled" > "$dev/power/wakeup" 2>/dev/null || true
    elif [[ $is_keyboard -eq 1 && $is_mouse -eq 1 ]]; then
        # Composite device (e.g. keyboard with trackpoint vs mouse with media keys):
        if [[ "$prod" =~ [Kk]eyboard|[Kk]ey|N-KEY || "$manuf" =~ [Kk]eyboard ]]; then
            # Genuine keyboard with embedded pointer (TrackPoint, touch panel)
            echo "enabled" > "$dev/power/wakeup" 2>/dev/null || true
        else
            # Mouse or wireless dongle with extra macro/multimedia keys: block wake
            echo "disabled" > "$dev/power/wakeup" 2>/dev/null || true
        fi
    else
        # Mouse, webcam, Bluetooth, or unknown peripheral: disable wake
        echo "disabled" > "$dev/power/wakeup" 2>/dev/null || true
    fi
done
