#!/usr/bin/env bash
# ==============================================================================
# Automatic Power Profile & GPU Switcher for AC / Battery Transitions
# Profile: ASUS ROG + NVIDIA RTX Laptop
# Dynamically detects AC power (barrel jack ADP0, USB-C PD, AC*) and updates:
# 1. Cardwire GPU Mode (Integrated on Battery vs Smart on AC)
# 2. System Power Profile (powerprofilesctl: power-saver vs performance)
# 3. CPU Energy Performance Preference (EPP: power vs balance_performance)
# ==============================================================================
set -euo pipefail

# Detach immediately when invoked by udev to avoid blocking event loops
if [[ "${1:-}" == "--async" ]]; then
    nohup "$0" --run-worker </dev/null >/dev/null 2>&1 &
    exit 0
fi

LOCKFILE="/run/power-profile-switch.lock"
exec 200>"$LOCKFILE" 2>/dev/null || exec 200>"/tmp/power-profile-switch.lock"

# Non-blocking lock: If a debounce routine is already running, avoid stampeding
flock -n 200 || exit 0

# Debounce to allow voltage rail to stabilize
sleep 2

# Check all power supply online attributes dynamically
target_state="battery"
grep -qs 1 /sys/class/power_supply/*/online && target_state="ac"

# Deduplicate state to prevent redundant writes and ACPI feedback loops
STATEFILE="/run/laptop-power-state"
[[ "$target_state" == "$(cat "$STATEFILE" 2>/dev/null || true)" ]] && exit 0
echo "$target_state" > "$STATEFILE" 2>/dev/null || true

if [[ "$target_state" == "ac" ]]; then
    # Plugged into AC (barrel jack or USB-C PD)
    if command -v cardwire >/dev/null 2>&1; then
        cardwire set smart 2>/dev/null || true
    fi
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set performance 2>/dev/null || true
    fi
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        [[ -w "$epp" ]] && echo "balance_performance" > "$epp" 2>/dev/null || true
    done
else
    # Running on Battery
    if command -v cardwire >/dev/null 2>&1; then
        cardwire set integrated 2>/dev/null || true
    fi
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set power-saver 2>/dev/null || true
    fi
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        [[ -w "$epp" ]] && echo "power" > "$epp" 2>/dev/null || true
    done
fi
