#!/bin/bash
THRESHOLD_FILE="/sys/class/power_supply/BAT0/charge_control_end_threshold"
if [[ -w "$THRESHOLD_FILE" ]]; then
    echo 85 > "$THRESHOLD_FILE"
elif [[ -f "$THRESHOLD_FILE" ]]; then
    echo 85 | sudo tee "$THRESHOLD_FILE" >/dev/null
fi
