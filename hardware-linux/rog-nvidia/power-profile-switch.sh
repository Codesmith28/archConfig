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

LOCKFILE="/run/power-profile-switch.lock"
exec 200>"$LOCKFILE" 2>/dev/null || exec 200>"/tmp/power-profile-switch.lock"

# Non-blocking lock: If a debounce routine is already running, avoid stampeding
flock -n 200 || exit 0

# Hysteresis debounce: Wait 4 seconds for power rail to stabilize before evaluating
# This eliminates stutter during momentary grid cutoffs, loose plugs, or inverter switches.
sleep 4

# Check all power supply online attributes dynamically
if grep -qs 1 /sys/class/power_supply/*/online; then
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
