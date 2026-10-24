#!/usr/bin/env bash
# ==============================================================================
# Battery Charging Limit & Deep Sleep Setup (85% Cap + S3 Suspend)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DEST="${1:-/usr/local/bin}"
SERVICE_DEST="${2:-/etc/systemd/system}"

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    echo "=== Battery Threshold Status Check ==="
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

# 1. Install executable
echo "Installing set-battery-limit.sh to $BIN_DEST..."
sudo cp "$SCRIPT_DIR/set-battery-limit.sh" "$BIN_DEST/set-battery-limit.sh"
sudo chmod +x "$BIN_DEST/set-battery-limit.sh"

# 2. Install systemd service
echo "Installing battery-limit.service to $SERVICE_DEST..."
sudo cp "$SCRIPT_DIR/battery-limit.service" "$SERVICE_DEST/battery-limit.service"
sudo chmod 644 "$SERVICE_DEST/battery-limit.service"

echo "Reloading systemd and enabling battery-limit.service..."
sudo systemctl daemon-reload
sudo systemctl enable --now battery-limit.service

# 3. Configure Deep Sleep (S3) if supported
if [[ -f /sys/power/mem_sleep ]] && grep -q "deep" /sys/power/mem_sleep; then
    echo "Configuring Deep Sleep (S3 / Suspend-to-RAM)..."
    
    # 3a. systemd-tmpfiles: write deep to /sys/power/mem_sleep on boot
    sudo mkdir -p /etc/tmpfiles.d
    echo "w /sys/power/mem_sleep - - - - deep" | sudo tee /etc/tmpfiles.d/deep-sleep.conf >/dev/null
    sudo chmod 644 /etc/tmpfiles.d/deep-sleep.conf

    # 3b. systemd sleep configuration drop-in: MemorySleepMode=deep
    sudo mkdir -p /etc/systemd/sleep.conf.d
    cat << 'EOF' | sudo tee /etc/systemd/sleep.conf.d/deep-sleep.conf >/dev/null
[Sleep]
MemorySleepMode=deep
EOF
    sudo chmod 644 /etc/systemd/sleep.conf.d/deep-sleep.conf

    # 3c. Kernel parameter persistence via grubby (Fedora BLS)
    if command -v grubby >/dev/null 2>&1 && { [ -d /boot/grub ] || [ -d /boot/grub2 ] || command -v grub-mkconfig >/dev/null 2>&1 || command -v grub2-mkconfig >/dev/null 2>&1; }; then
        echo "→ Injecting mem_sleep_default=deep into GRUB via grubby..."
        sudo grubby --update-kernel=ALL --args="mem_sleep_default=deep" 2>/dev/null || true
    fi

    # 3d. Apply immediately to active kernel session if writable
    if [[ -w /sys/power/mem_sleep ]]; then
        echo "deep" > /sys/power/mem_sleep 2>/dev/null || true
    fi
fi
