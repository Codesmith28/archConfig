#!/usr/bin/env bash
# ==============================================================================
# Universal Battery Charging Limit & Threshold Controller
# ==============================================================================

# Target battery charging cap percentage (e.g. 80, 85, 100 to disable cap).
# Overridable via CLI argument ($1) or BATTERY_LIMIT environment variable.
BATTERY_LIMIT="${1:-${BATTERY_LIMIT:-80}}"

# Validate input limit (1-100)
if ! [[ "$BATTERY_LIMIT" =~ ^[0-9]+$ ]] || [ "$BATTERY_LIMIT" -lt 1 ] || [ "$BATTERY_LIMIT" -gt 100 ]; then
    echo "Error: BATTERY_LIMIT must be an integer between 1 and 100 (got: '$BATTERY_LIMIT')" >&2
    exit 1
fi

write_node() {
    local val="$1" node="$2"
    if [ "$EUID" -eq 0 ]; then
        echo "$val" > "$node" 2>/dev/null
    else
        echo "$val" | sudo tee "$node" >/dev/null 2>&1
    fi
}

applied=0

# 1. Standard Linux power_supply class (ASUS, ThinkPad, Dell, Framework, Apple Silicon, etc.)
for psy in /sys/class/power_supply/*; do
    [ -d "$psy" ] || continue

    # Ensure device is a battery
    if [ -f "$psy/type" ]; then
        psy_type="$(cat "$psy/type" 2>/dev/null)"
        [ "$psy_type" != "Battery" ] && continue
    fi

    # Adjust start threshold first if present to prevent kernel EINVAL (start must be < end)
    start_node="$psy/charge_control_start_threshold"
    if [ -f "$start_node" ]; then
        current_start="$(cat "$start_node" 2>/dev/null || echo 0)"
        if [ "$current_start" -ge "$BATTERY_LIMIT" ]; then
            new_start=$(( BATTERY_LIMIT > 5 ? BATTERY_LIMIT - 5 : 0 ))
            write_node "$new_start" "$start_node"
        fi
    fi

    # Apply end/stop threshold
    for end_node in "$psy/charge_control_end_threshold" "$psy/charge_stop_threshold"; do
        if [ -f "$end_node" ]; then
            if write_node "$BATTERY_LIMIT" "$end_node"; then
                applied=1
                echo "Set charging limit to ${BATTERY_LIMIT}% on $(basename "$psy")"
            fi
        fi
    done
done

# 2. Lenovo IdeaPad / LOQ / Legion conservation mode (1 = enable cap ~80%, 0 = full charge 100%)
if [ "$applied" -eq 0 ]; then
    cm_val=$(( BATTERY_LIMIT < 100 ? 1 : 0 ))
    for cm_node in /sys/bus/platform/drivers/ideapad_*/*/conservation_mode /sys/devices/platform/VPC*/conservation_mode; do
        if [ -f "$cm_node" ]; then
            if write_node "$cm_val" "$cm_node"; then
                applied=1
                echo "Lenovo Conservation Mode set to $cm_val ($cm_node)"
            fi
        fi
    done
fi

# 3. LG Gram and Sony Vaio vendor interfaces
if [ "$applied" -eq 0 ]; then
    for vendor_node in /sys/devices/platform/lg-laptop/battery_care_limit /sys/devices/platform/sony-laptop/battery_care_limiter; do
        if [ -f "$vendor_node" ]; then
            if write_node "$BATTERY_LIMIT" "$vendor_node"; then
                applied=1
                echo "Set battery limit to ${BATTERY_LIMIT}% on $(basename "$vendor_node")"
            fi
        fi
    done
fi

if [ "$applied" -eq 0 ]; then
    echo "Notice: No supported hardware battery charge threshold found on this device." >&2
fi

exit 0
