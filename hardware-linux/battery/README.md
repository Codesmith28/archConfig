# Battery Charging Limit & Deep Sleep Management

Configures the battery charging threshold and deep sleep for Linux:

1. **Battery Charging Cap (85%) Multi-Layer Persistence**:
   - Configuration file: `/etc/default/battery-limit` (`BATTERY_LIMIT=85`).
   - Systemd Service: `/etc/systemd/system/battery-limit.service` runs on system boot.
   - Sleep / Wake Hook: `/usr/lib/systemd/system-sleep/battery-limit.sh` re-enforces the threshold immediately upon resume from suspend or hibernate.
   - Udev Rule: `/etc/udev/rules.d/90-battery-limit.rules` re-enforces the threshold whenever power supplies change (AC adapter plug/unplug).
   - Executable Controller: `/usr/local/bin/set-battery-limit.sh` automatically writes to `/sys/class/power_supply/BAT*/charge_control_end_threshold`. If older ASUS EC firmware strictly mandates discrete steps (60, 80, 100) and rejects 85, it gracefully falls back to 80% to protect battery health.

2. **Deep Sleep (S3 Suspend-to-RAM)**:
   - Sysfs injection via `/etc/tmpfiles.d/deep-sleep.conf`
   - systemd drop-in `/etc/systemd/sleep.conf.d/deep-sleep.conf`
   - Kernel command-line argument `mem_sleep_default=deep` via `grubby`

---

## Commands

```bash
# Verify active battery threshold & sleep status:
./setup.sh --verify

# Apply / Install:
sudo ./setup.sh
```
