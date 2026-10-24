#!/usr/bin/env bash
# ==============================================================================
# Battery Charging Limit & Deep Sleep Setup (85% Cap + S3 Suspend)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DEST="${1:-/usr/local/bin}"
SERVICE_DEST="${2:-/etc/systemd/system}"
SLEEP_DEST="/usr/lib/systemd/system-sleep"
[ -d "$SLEEP_DEST" ] || SLEEP_DEST="/etc/systemd/system-sleep"

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    echo "=== Battery Threshold Status Check ==="
    if [ -f /etc/default/battery-limit ]; then
        echo "Configuration (/etc/default/battery-limit): $(grep -v '^[[:space:]]*#' /etc/default/battery-limit | grep 'BATTERY_LIMIT' | tr -d '\n')"
    else
        echo "Configuration (/etc/default/battery-limit): not found (default 85%)"
    fi
    for psy in /sys/class/power_supply/*; do
        if [ -f "$psy/type" ] && [ "$(cat "$psy/type" 2>/dev/null)" = "Battery" ]; then
            echo "Device: $(basename "$psy")"
            for node in charge_control_end_threshold charge_stop_threshold; do
                if [ -f "$psy/$node" ]; then
                    echo "  $node: $(cat "$psy/$node" 2>/dev/null)%"
                fi
            done
        fi
    done
    state=$(systemctl is-enabled battery-limit.service 2>/dev/null || echo "not-found")
    echo "battery-limit.service status: $state"
    if [ -x /usr/lib/systemd/system-sleep/battery-limit.sh ] || [ -x /etc/systemd/system-sleep/battery-limit.sh ]; then
        echo "system-sleep resume hook: installed"
    else
        echo "system-sleep resume hook: not found"
    fi
    if [ -f /etc/udev/rules.d/90-battery-limit.rules ]; then
        echo "udev rule: /etc/udev/rules.d/90-battery-limit.rules active"
    else
        echo "udev rule: not found"
    fi
    echo "=== Sleep / Suspend Mode Check ==="
    if [ -f /sys/power/mem_sleep ]; then
        echo "mem_sleep modes: $(cat /sys/power/mem_sleep)"
    fi
    if [ -f /etc/tmpfiles.d/deep-sleep.conf ]; then
        echo "tmpfiles.d deep-sleep config: present ($(cat /etc/tmpfiles.d/deep-sleep.conf 2>/dev/null | tr -d '\n'))"
    fi
    if [ -f /etc/systemd/sleep.conf.d/deep-sleep.conf ]; then
        echo "systemd MemorySleepMode: deep configured"
    fi
    if grep -q "mem_sleep_default=deep" /proc/cmdline 2>/dev/null; then
        echo "kernel cmdline: mem_sleep_default=deep active"
    else
        echo "kernel cmdline: mem_sleep_default=deep not active in current boot"
    fi
    exit 0
fi

# 1. Install persistent configuration file
echo "Configuring /etc/default/battery-limit (85% cap)..."
sudo mkdir -p /etc/default
sudo cp "$SCRIPT_DIR/default-battery-limit" /etc/default/battery-limit
sudo chmod 644 /etc/default/battery-limit

# 2. Install executable
echo "Installing set-battery-limit.sh to $BIN_DEST..."
sudo cp "$SCRIPT_DIR/set-battery-limit.sh" "$BIN_DEST/set-battery-limit.sh"
sudo chmod +x "$BIN_DEST/set-battery-limit.sh"

# 3. Install systemd service
echo "Installing battery-limit.service to $SERVICE_DEST..."
sudo cp "$SCRIPT_DIR/battery-limit.service" "$SERVICE_DEST/battery-limit.service"
sudo chmod 644 "$SERVICE_DEST/battery-limit.service"

# 4. Install sleep / resume hook
echo "Installing battery-limit sleep resume hook to $SLEEP_DEST..."
sudo mkdir -p "$SLEEP_DEST"
sudo cp "$SCRIPT_DIR/battery-sleep.sh" "$SLEEP_DEST/battery-limit.sh"
sudo chmod +x "$SLEEP_DEST/battery-limit.sh"

# 5. Install udev rule for power events
echo "Installing udev rule /etc/udev/rules.d/90-battery-limit.rules..."
sudo cp "$SCRIPT_DIR/90-battery-limit.rules" /etc/udev/rules.d/90-battery-limit.rules
sudo chmod 644 /etc/udev/rules.d/90-battery-limit.rules
if command -v udevadm >/dev/null 2>&1; then
    sudo udevadm control --reload-rules 2>/dev/null || true
fi

# 6. Enable systemd service and apply immediately
echo "Reloading systemd and enabling battery-limit.service..."
sudo systemctl daemon-reload
sudo systemctl enable --now battery-limit.service

# 7. Configure Deep Sleep (S3) if supported
if [[ -f /sys/power/mem_sleep ]] && grep -q "deep" /sys/power/mem_sleep; then
    echo "Configuring Deep Sleep (S3 / Suspend-to-RAM)..."
    
    # 7a. systemd-tmpfiles: write deep to /sys/power/mem_sleep on boot
    sudo mkdir -p /etc/tmpfiles.d
    echo "w /sys/power/mem_sleep - - - - deep" | sudo tee /etc/tmpfiles.d/deep-sleep.conf >/dev/null
    sudo chmod 644 /etc/tmpfiles.d/deep-sleep.conf

    # 7b. systemd sleep configuration drop-in: MemorySleepMode=deep
    sudo mkdir -p /etc/systemd/sleep.conf.d
    cat << 'EOF' | sudo tee /etc/systemd/sleep.conf.d/deep-sleep.conf >/dev/null
[Sleep]
MemorySleepMode=deep
EOF
    sudo chmod 644 /etc/systemd/sleep.conf.d/deep-sleep.conf

    # 7c. Kernel parameter persistence via grubby (Fedora BLS)
    if command -v grubby >/dev/null 2>&1 && { [ -d /boot/grub ] || [ -d /boot/grub2 ] || command -v grub-mkconfig >/dev/null 2>&1 || command -v grub2-mkconfig >/dev/null 2>&1; }; then
        echo "→ Injecting mem_sleep_default=deep into GRUB via grubby..."
        sudo grubby --update-kernel=ALL --args="mem_sleep_default=deep" 2>/dev/null || true
    fi

    # 7d. Apply immediately to active kernel session if writable
    if [[ -w /sys/power/mem_sleep ]]; then
        echo "deep" > /sys/power/mem_sleep 2>/dev/null || true
    fi
fi
