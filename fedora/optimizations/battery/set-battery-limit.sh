#!/usr/bin/env bash
# ==============================================================================
# Set Battery Charging Limit (Charge Threshold)
# ==============================================================================
# Sets battery charge threshold (default: 85%) to preserve battery lifespan.
# Supports ASUS ROG/TUF systems (via asusctl / asusd) and generic Linux kernel
# sysfs nodes (charge_control_end_threshold / charge_stop_threshold).
# Handles boot, resume from suspend/hibernate, and AC adapter plug/unplug events.
# ==============================================================================
set -euo pipefail

# Ensure standard binary PATH is available (critical for udev and systemd-sleep hooks)
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:${PATH:-}"

# If invoked by systemd-sleep hook ($1 = pre|post), only execute on post-suspend resume
if [[ "${1:-}" == "pre" ]]; then
    exit 0
fi

# Determine threshold percentage (default: 85, range: 20-100)
THRESHOLD="${BATTERY_LIMIT:-85}"
if [[ -n "${1:-}" && "$1" =~ ^[0-9]+$ && "$1" -ge 20 && "$1" -le 100 ]]; then
    THRESHOLD="$1"
fi

echo "[INFO] Setting battery charging limit to ${THRESHOLD}%..."
success=0

# ------------------------------------------------------------------------------
# 1. ASUS ROG / TUF Hardware via asusctl / asusd (Native D-Bus daemon)
# ------------------------------------------------------------------------------
# asusctl configures asusd, which updates hardware registers and permanently
# stores charge_control_end_threshold in /etc/asusd/asusd.ron.
if command -v asusctl >/dev/null 2>&1; then
    if asusctl battery limit "$THRESHOLD" 2>/dev/null; then
        echo "[OK] Battery charging threshold set via asusctl: ${THRESHOLD}%"
        success=1
    fi
fi

# ------------------------------------------------------------------------------
# 2. Native Linux Kernel sysfs nodes
# ------------------------------------------------------------------------------
# Supports charge_control_end_threshold and charge_stop_threshold across all vendors
SYSFS_NODES=()
for pattern in /sys/class/power_supply/*/charge_control_end_threshold /sys/class/power_supply/*/charge_stop_threshold; do
    for node in $pattern; do
        [[ -f "$node" ]] && SYSFS_NODES+=("$node")
    done
done

for node in "${SYSFS_NODES[@]}"; do
    curr=$(cat "$node" 2>/dev/null || echo "")
    if [[ "$curr" == "$THRESHOLD" ]]; then
        echo "[OK] Battery threshold verified at $node: ${curr}%"
        success=1
        continue
    fi

    node_written=0
    if [[ -w "$node" || "$(id -u)" -eq 0 ]]; then
        if echo "$THRESHOLD" > "$node" 2>/dev/null; then
            node_written=1
        fi
    elif sudo -n true 2>/dev/null; then
        if echo "$THRESHOLD" | sudo -n tee "$node" >/dev/null 2>&1; then
            node_written=1
        fi
    fi

    # Read back to verify
    curr=$(cat "$node" 2>/dev/null || echo "")
    if [[ "$curr" == "$THRESHOLD" ]]; then
        echo "[OK] Battery threshold verified at $node: ${curr}%"
        success=1
    elif [[ $node_written -eq 1 ]]; then
        echo "[INFO] Battery threshold written to $node (reading: ${curr:-unknown}%)"
        success=1
    fi
done

# ------------------------------------------------------------------------------
# 3. Validation & Reporting
# ------------------------------------------------------------------------------
if [[ $success -eq 1 ]]; then
    echo "[OK] Battery charging limit successfully applied (${THRESHOLD}%)."
    exit 0
else
    echo "[ERR] Failed to set battery charging threshold. No supported controller or writable sysfs node found."
    exit 1
fi
