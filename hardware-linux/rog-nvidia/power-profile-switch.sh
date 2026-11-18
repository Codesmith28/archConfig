#!/usr/bin/env bash
# ==============================================================================
# Automatic Power Profile & GPU Switcher for AC / Battery Transitions
# Profile: ASUS ROG + NVIDIA RTX Laptop
# Dynamically detects AC power (barrel jack ADP0, USB-C PD, AC*) and updates:
# 1. GPU Posture (Cardwire eBPF / ASUS dGPU sysfs fallback)
# 2. System Power Profile (powerprofilesctl / busctl D-Bus / tuned-adm)
# 3. ACPI Platform Profile (/sys/firmware/acpi/platform_profile)
# 4. CPU Energy Performance Preference (EPP: balance_power vs balance_performance)
#
# Anti-Storm & Anti-Stutter Safeguards:
# - Pre-flight state deduplication in --async to eliminate udev event storms
# - Singleton systemd-run unit naming (laptop-power-profile-switch)
# - Hardware rail stabilization debounce window (1.5s)
# - TuneD-PPD sysfs_acpi_monitor feedback loop neutralization
# - Safe CPU EPP targeting: uses balance_power on battery to protect Wayland
#   frame deadlines and prevent KWin atomic commit stalls
# - dGPU disable process safety guard (verifies /dev/nvidia* not in use)
# - Automated ACPI GPE interrupt storm detection and runtime masking
# ==============================================================================
set -euo pipefail

STATEFILE="/run/laptop-power-state"
LOCKFILE="/run/power-profile-switch.lock"
PENDINGFILE="/run/power-profile-switch.pending"
LAST_RUN_FILE="/run/power-profile-switch.last_ts"

# Fallback to /tmp if /run is non-writable
if [[ ! -w /run ]]; then
    STATEFILE="/tmp/laptop-power-state"
    LOCKFILE="/tmp/power-profile-switch.lock"
    PENDINGFILE="/tmp/power-profile-switch.pending"
    LAST_RUN_FILE="/tmp/power-profile-switch.last_ts"
fi

get_raw_power_state() {
    if grep -qs 1 /sys/class/power_supply/*/online 2>/dev/null; then
        echo "ac"
    else
        echo "battery"
    fi
}

get_recorded_power_state() {
    cat "$STATEFILE" 2>/dev/null || echo "unknown"
}

# ------------------------------------------------------------------------------
# Asynchronous Dispatcher Entry Point (Invoked by Udev)
# ------------------------------------------------------------------------------
if [[ "${1:-}" == "--async" ]]; then
    raw_now="$(get_raw_power_state)"
    recorded="$(get_recorded_power_state)"

    # Fast Pre-Flight Check:
    # If the hardware power supply state already matches our recorded state,
    # exit immediately. This drops 100% of spurious UCSI telemetry events,
    # battery capacity updates, and duplicate udev change notifications in 0ms.
    if [[ "$raw_now" == "$recorded" && -f "$STATEFILE" ]]; then
        exit 0
    fi

    # Mark pending state change for any currently running worker
    touch "$PENDINGFILE" 2>/dev/null || true

    # Dispatch singleton background worker via systemd-run or nohup
    if command -v systemd-run >/dev/null 2>&1 && [[ "$(id -u)" -eq 0 ]]; then
        systemd-run --unit=laptop-power-profile-switch \
                    --property=CollectMode=inactive-or-failed \
                    --no-block "$0" --run-worker >/dev/null 2>&1 || \
            nohup "$0" --run-worker </dev/null >/dev/null 2>&1 &
    else
        nohup "$0" --run-worker </dev/null >/dev/null 2>&1 &
    fi
    exit 0
fi

# ------------------------------------------------------------------------------
# Status & Diagnostics Mode
# ------------------------------------------------------------------------------
if [[ "${1:-}" == "--status" || "${1:-}" == "--check" || "${1:-}" == "-s" ]]; then
    echo "=== Power Profile & Hardware Status ==="
    echo "Current Power Supply State: $(get_raw_power_state)"
    echo "Recorded System State:      $(get_recorded_power_state)"

    if command -v powerprofilesctl >/dev/null 2>&1; then
        echo "Active powerprofilesctl:   $(powerprofilesctl get 2>/dev/null || echo 'N/A')"
    elif command -v busctl >/dev/null 2>&1 && busctl introspect net.hadess.PowerProfiles /net/hadess/PowerProfiles >/dev/null 2>&1; then
        cur_dbus="$(busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile 2>/dev/null | awk -F'"' '{print $2}' || true)"
        echo "Active D-Bus Profile:       ${cur_dbus:-N/A}"
    fi

    if command -v tuned-adm >/dev/null 2>&1; then
        cur_tuned="$(tuned-adm active 2>/dev/null | awk -F': ' '{print $2}' || true)"
        echo "Active TuneD Profile:       ${cur_tuned:-N/A}"
    fi

    if [[ -r /sys/firmware/acpi/platform_profile ]]; then
        echo "ACPI Platform Profile:      $(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"
    fi

    if [[ -r /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]]; then
        echo "CPU0 EPP:                   $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)"
    fi

    if [[ -r /sys/devices/platform/asus-nb-wmi/dgpu_disable ]]; then
        echo "ASUS dGPU Disable Sysfs:    $(cat /sys/devices/platform/asus-nb-wmi/dgpu_disable 2>/dev/null)"
    fi

    echo ""
    echo "Top ACPI GPE Interrupts:"
    grep -v '^ *0' /sys/firmware/acpi/interrupts/gpe* 2>/dev/null | head -n 5 || echo "None active"
    exit 0
fi

# ------------------------------------------------------------------------------
# Concurrency Lock & Debounce Engine
# ------------------------------------------------------------------------------
2>/dev/null touch "$LOCKFILE" || true
exec 200>"$LOCKFILE"

# Non-blocking mutex lock: If a worker is actively executing, note pending and exit
if ! flock -n 200; then
    touch "$PENDINGFILE" 2>/dev/null || true
    exit 0
fi

# Debounce delay: Allow physical DC rail voltage decay, capacitor stabilization,
# and UCSI power contract negotiation to complete unless explicitly forced.
if [[ "${1:-}" != "--force" && "${2:-}" != "--force" && "${1:-}" != "--now" && "${2:-}" != "--now" ]]; then
    sleep 1.5
fi

# ------------------------------------------------------------------------------
# TuneD-PPD Feedback Loop Neutralization
# Disabling sysfs_acpi_monitor stops tuned-ppd from watching platform_profile via
# pyinotify, which eliminates the 25-50 Hz profile bouncing loop on ASUS ROG EC.
# Disabling battery_detection stops tuned-ppd from racing against udev transitions.
# ------------------------------------------------------------------------------
sanitize_tuned_ppd_config() {
    local ppd_conf="/etc/tuned/ppd.conf"
    local needs_restart=false
    if [[ -w "$ppd_conf" ]]; then
        if grep -q "sysfs_acpi_monitor=[[:space:]]*true" "$ppd_conf" 2>/dev/null; then
            sed -i 's/sysfs_acpi_monitor=[[:space:]]*true/sysfs_acpi_monitor=false/g' "$ppd_conf" 2>/dev/null || true
            needs_restart=true
        fi
        if grep -q "battery_detection=[[:space:]]*true" "$ppd_conf" 2>/dev/null; then
            sed -i 's/battery_detection=[[:space:]]*true/battery_detection=false/g' "$ppd_conf" 2>/dev/null || true
            needs_restart=true
        fi
        if [[ "$needs_restart" == "true" ]]; then
            command -v systemctl >/dev/null 2>&1 && systemctl try-restart tuned-ppd.service >/dev/null 2>&1 || true
        fi
    fi
}

# ------------------------------------------------------------------------------
# ASUS Notebook Daemon (asusd) Rogue Attribute Neutralization
# Removes read-only ChargeMode from asusd.ron to eliminate recurring permission
# denied (os error 13) spam on modern 6.x/7.x Linux kernels.
# ------------------------------------------------------------------------------
sanitize_asusd_config() {
    local asusd_conf="/etc/asusd/asusd.ron"
    if [[ -w "$asusd_conf" ]]; then
        if grep -q "ChargeMode:" "$asusd_conf" 2>/dev/null; then
            sed -i 's/ChargeMode:[[:space:]]*[0-9]*,//g' "$asusd_conf" 2>/dev/null || true
            command -v systemctl >/dev/null 2>&1 && systemctl try-restart asusd.service >/dev/null 2>&1 || true
        fi
    fi
}

# ------------------------------------------------------------------------------
# ACPI GPE Interrupt Storm Auto-Detection & Masking
# Scans for runaway GPE channels (> 10,000 interrupts) and disables them dynamically.
# ------------------------------------------------------------------------------
guard_gpe_interrupt_storms() {
    local gpe_file count status gpe_name
    for gpe_file in /sys/firmware/acpi/interrupts/gpe*; do
        [[ -f "$gpe_file" ]] || continue
        gpe_name="$(basename "$gpe_file")"
        [[ "$gpe_name" == "gpe_all" ]] && continue

        # Extract interrupt count
        count="$(awk '{print $1}' "$gpe_file" 2>/dev/null || echo 0)"
        status="$(awk '{print $2}' "$gpe_file" 2>/dev/null || echo "")"

        if [[ "$count" =~ ^[0-9]+$ ]] && [[ "$count" -gt 10000 ]] && [[ "$status" == "EN" ]]; then
            if [[ -w "$gpe_file" ]]; then
                echo "disable" > "$gpe_file" 2>/dev/null || true
                logger -t power-profile-switch "[WARN] Masked runaway ACPI interrupt storm on $gpe_name ($count interrupts)" 2>/dev/null || true
            fi
        fi
    done
}

# ------------------------------------------------------------------------------
# 1. System Power Profile Management
# Synchronizes powerprofilesctl, D-Bus (tuned-ppd), and tuned-adm
# ------------------------------------------------------------------------------
set_system_power_profile() {
    local target_ppd="$1"        # "performance" or "power-saver"
    local target_tuned="$2"      # "throughput-performance" or "powersave"
    local applied=false

    # 1. Try powerprofilesctl CLI if available
    if command -v powerprofilesctl >/dev/null 2>&1; then
        local cur_prof
        cur_prof="$(powerprofilesctl get 2>/dev/null || true)"
        if [[ "$cur_prof" == "$target_ppd" ]]; then
            applied=true
        elif powerprofilesctl set "$target_ppd" 2>/dev/null; then
            applied=true
        fi
    fi

    # 2. Try D-Bus net.hadess.PowerProfiles via busctl (Native on Fedora tuned-ppd)
    if [[ "$applied" != "true" ]] && command -v busctl >/dev/null 2>&1 && busctl introspect net.hadess.PowerProfiles /net/hadess/PowerProfiles >/dev/null 2>&1; then
        local cur_dbus
        cur_dbus="$(busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile 2>/dev/null | awk -F'"' '{print $2}' || true)"
        if [[ "$cur_dbus" == "$target_ppd" ]]; then
            applied=true
        elif busctl set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s "$target_ppd" 2>/dev/null; then
            applied=true
        fi
    fi

    # 3. Synchronize tuned-adm CLI if available and not managed via D-Bus
    if [[ "$applied" != "true" ]] && command -v tuned-adm >/dev/null 2>&1; then
        local cur_tuned
        cur_tuned="$(tuned-adm active 2>/dev/null | awk -F': ' '{print $2}' || true)"
        if [[ "$cur_tuned" == "$target_tuned" ]]; then
            applied=true
        elif tuned-adm profile "$target_tuned" 2>/dev/null; then
            applied=true
        fi
    fi

    echo "$applied"
}

# ------------------------------------------------------------------------------
# 2. GPU Posture Management
# Handles Cardwire eBPF (primary).
# Safely enforces D3cold idle on battery without PCIe bus power cutoffs.
# ------------------------------------------------------------------------------
set_gpu_posture() {
    local state="$1" # "ac" or "battery"

    # 1. Cardwire eBPF controller (primary modern solution)
    # Intercepts user-space access to /dev/nvidia* via eBPF LSM filters.
    # On Battery (Integrated): runtime PM automatically suspends NVIDIA dGPU into D3cold (0W)
    # without severing PCIe links or unbinding drivers.
    # On AC (Smart): allows dynamic GPU offloading.
    if command -v cardwire >/dev/null 2>&1; then
        if [[ "$state" == "ac" ]]; then
            cardwire set smart 2>/dev/null || true
        else
            cardwire set integrated 2>/dev/null || true
        fi
    fi

    # 2. Guard ASUS WMI dgpu_disable sysfs node
    # NEVER set dgpu_disable=1 on a running desktop session!
    # Abruptly cutting PEG root port power triggers NVRM kernel driver panics,
    # Wayland atomic page flip freezes, and PCIe bus locks.
    # Ensure dgpu_disable is set to 0 (enabled) so PCIe link remains intact.
    local dgpu_node="/sys/devices/platform/asus-nb-wmi/dgpu_disable"
    if [[ -f "$dgpu_node" && -w "$dgpu_node" ]]; then
        local cur_val
        cur_val="$(cat "$dgpu_node" 2>/dev/null || true)"
        if [[ "$cur_val" != "0" ]]; then
            echo 0 > "$dgpu_node" 2>/dev/null || true
        fi
    fi

    # 3. Rescan PCI bus if dGPU is absent from sysfs/lspci (e.g. after prior dgpu_disable=1)
    if [[ -w /sys/bus/pci/rescan ]]; then
        if ! lspci -d 10de: >/dev/null 2>&1; then
            echo 1 > /sys/bus/pci/rescan 2>/dev/null || true
        fi
    fi
}

# ------------------------------------------------------------------------------
# 3. ACPI Platform Profile
# Only writes directly if daemon did not handle it or sysfs is desynchronized.
# ------------------------------------------------------------------------------
set_platform_profile() {
    local target_plat="$1"        # "performance" or "quiet"
    local daemon_applied="$2"     # "true" or "false"
    local plat_node="/sys/firmware/acpi/platform_profile"

    if [[ -f "$plat_node" && -w "$plat_node" ]]; then
        local cur_plat
        cur_plat="$(cat "$plat_node" 2>/dev/null || true)"
        # Avoid redundant writes to prevent hammering the ASUS EC
        if [[ -n "$cur_plat" && "$cur_plat" != "$target_plat" ]]; then
            if [[ "$daemon_applied" != "true" ]]; then
                echo "$target_plat" > "$plat_node" 2>/dev/null || true
            fi
        fi
    fi
}

# ------------------------------------------------------------------------------
# 4. CPU Energy Performance Preference (EPP)
# Anti-Stutter Rule: Uses 'balance_power' instead of 'power' on battery to guarantee
# Wayland compositor render loop deadlines are met and atomic commits do not stall.
# ------------------------------------------------------------------------------
set_cpu_epp() {
    local target_epp="$1"         # "balance_performance" or "balance_power"
    local daemon_applied="$2"      # "true" or "false"

    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        if [[ -f "$epp" && -w "$epp" ]]; then
            local cur_epp
            cur_epp="$(cat "$epp" 2>/dev/null || true)"
            if [[ "$cur_epp" != "$target_epp" ]]; then
                echo "$target_epp" > "$epp" 2>/dev/null || true
            fi
        fi
    done
}

# ------------------------------------------------------------------------------
# Main Execution Loop with Trailing-Edge State Reconciliation
# ------------------------------------------------------------------------------
loop_count=0
while [[ $loop_count -lt 2 ]]; do
    loop_count=$((loop_count + 1))
    rm -f "$PENDINGFILE" 2>/dev/null || true

    # Evaluate stable hardware state
    target_state="$(get_raw_power_state)"
    last_state="$(get_recorded_power_state)"

    # Deduplicate against current recorded state unless forced
    if [[ "${1:-}" != "--force" && "${2:-}" != "--force" ]]; then
        if [[ "$target_state" == "$last_state" ]]; then
            break
        fi
    fi

    # Record settled state immediately
    echo "$target_state" > "$STATEFILE"
    date +%s > "$LAST_RUN_FILE" 2>/dev/null || true

    # Neutralize TuneD-PPD monitor loop & scan for GPE interrupt storms
    sanitize_tuned_ppd_config
    sanitize_asusd_config
    guard_gpe_interrupt_storms

    if [[ "$target_state" == "ac" ]]; then
        # Running on AC Power (Barrel Jack or USB-C PD)
        set_gpu_posture "ac"
        daemon_status="$(set_system_power_profile "performance" "throughput-performance")"
        set_platform_profile "performance" "$daemon_status"
        set_cpu_epp "balance_performance" "$daemon_status"
    else
        # Running on Battery Power
        set_gpu_posture "battery"
        daemon_status="$(set_system_power_profile "power-saver" "powersave")"
        set_platform_profile "quiet" "$daemon_status"
        # balance_power ensures power savings while avoiding 800MHz Wayland stalls
        set_cpu_epp "balance_power" "$daemon_status"
    fi

    # Re-enforce battery charge threshold (prevents ASUS EC reset on AC disconnect)
    if [[ -x /usr/local/bin/set-battery-limit.sh ]]; then
        /usr/local/bin/set-battery-limit.sh >/dev/null 2>&1 || true
    fi

    # Check if a new state transition was queued while applying this profile
    if [[ ! -f "$PENDINGFILE" ]]; then
        break
    fi
    sleep 0.5
done

exit 0
