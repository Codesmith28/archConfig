#!/usr/bin/env bash
# ==============================================================================
# Automatic Power Profile & GPU Switcher for AC / Battery Transitions
# Profile: ASUS ROG + NVIDIA RTX Laptop
# Dynamically detects AC power (barrel jack ADP0, USB-C PD, AC*) and updates:
# 1. GPU Posture (Cardwire eBPF / supergfxctl / ASUS dGPU sysfs)
# 2. System Power Profile (powerprofilesctl / busctl D-Bus / tuned-adm)
# 3. ACPI Platform Profile (/sys/firmware/acpi/platform_profile)
# 4. CPU Energy Performance Preference (EPP: power vs balance_performance)
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

# ------------------------------------------------------------------------------
# 1. System Power Profile Management
# Synchronizes powerprofilesctl, D-Bus (tuned-ppd), and tuned-adm
# ------------------------------------------------------------------------------
set_system_power_profile() {
    local target_ppd="$1"        # "performance" or "power-saver"
    local target_tuned="$2"      # "throughput-performance" or "powersave"

    # 1. Try powerprofilesctl CLI if available
    if command -v powerprofilesctl >/dev/null 2>&1; then
        local cur_prof
        cur_prof="$(powerprofilesctl get 2>/dev/null || true)"
        if [[ "$cur_prof" != "$target_ppd" ]]; then
            powerprofilesctl set "$target_ppd" 2>/dev/null || true
        fi
    # 2. Try D-Bus net.hadess.PowerProfiles via busctl (Native on Fedora tuned-ppd)
    elif command -v busctl >/dev/null 2>&1 && busctl introspect net.hadess.PowerProfiles /net/hadess/PowerProfiles >/dev/null 2>&1; then
        local cur_dbus
        cur_dbus="$(busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile 2>/dev/null | awk -F'"' '{print $2}' || true)"
        if [[ -n "$cur_dbus" && "$cur_dbus" != "$target_ppd" ]]; then
            busctl set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s "$target_ppd" 2>/dev/null || true
        fi
    # 3. Synchronize tuned-adm CLI if available
    elif command -v tuned-adm >/dev/null 2>&1; then
        local cur_tuned
        cur_tuned="$(tuned-adm active 2>/dev/null | awk -F': ' '{print $2}' || true)"
        if [[ "$cur_tuned" != "$target_tuned" ]]; then
            tuned-adm profile "$target_tuned" 2>/dev/null || true
        fi
    fi
}

# ------------------------------------------------------------------------------
# 2. GPU Posture Management
# Handles Cardwire eBPF and supergfxctl
# ------------------------------------------------------------------------------
set_gpu_posture() {
    local state="$1" # "ac" or "battery"

    if command -v cardwire >/dev/null 2>&1; then
        if [[ "$state" == "ac" ]]; then
            cardwire set smart 2>/dev/null || true
        else
            cardwire set integrated 2>/dev/null || true
        fi
    fi

    if command -v supergfxctl >/dev/null 2>&1; then
        if [[ "$state" == "ac" ]]; then
            supergfxctl -m Hybrid 2>/dev/null || true
        else
            supergfxctl -m Integrated 2>/dev/null || true
        fi
    fi
}

# ------------------------------------------------------------------------------
# 3. CPU Energy Performance Preference (EPP)
# ------------------------------------------------------------------------------
set_cpu_epp() {
    local target_epp="$1" # "balance_performance" or "power"
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        if [[ -w "$epp" ]]; then
            local cur_epp
            cur_epp="$(cat "$epp" 2>/dev/null || true)"
            if [[ "$cur_epp" != "$target_epp" ]]; then
                echo "$target_epp" > "$epp" 2>/dev/null || true
            fi
        fi
    done
}

# ------------------------------------------------------------------------------
# 4. ACPI Platform Profile
# ------------------------------------------------------------------------------
set_platform_profile() {
    local target_plat="$1" # "performance" or "quiet"
    local plat_node="/sys/firmware/acpi/platform_profile"
    if [[ -w "$plat_node" ]]; then
        local cur_plat
        cur_plat="$(cat "$plat_node" 2>/dev/null || true)"
        if [[ -n "$cur_plat" && "$cur_plat" != "$target_plat" ]]; then
            echo "$target_plat" > "$plat_node" 2>/dev/null || true
        fi
    fi
}

if [[ "$target_state" == "ac" ]]; then
    # Plugged into AC (barrel jack or USB-C PD)
    set_gpu_posture "ac"
    set_system_power_profile "performance" "throughput-performance"
    set_platform_profile "performance"
    set_cpu_epp "balance_performance"
else
    # Running on Battery
    set_gpu_posture "battery"
    set_system_power_profile "power-saver" "powersave"
    set_platform_profile "quiet"
    set_cpu_epp "power"
fi

# 5. Re-enforce battery limit if present (prevents ASUS EC reset on AC plug/unplug)
if [[ -x /usr/local/bin/set-battery-limit.sh ]]; then
    /usr/local/bin/set-battery-limit.sh >/dev/null 2>&1 || true
fi

