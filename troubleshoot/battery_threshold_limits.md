# Troubleshooting: Battery Charge Limits & Threshold Optimizations

On modern Linux kernels, hardware battery charging thresholds are exposed through the sysfs power supply subsystem (`/sys/class/power_supply/`). If your laptop's embedded controller (EC) and ACPI driver support charge thresholds (common on ThinkPads, ASUS, Lenovo IdeaPads, Framework, and Dell), you can enforce a charge limit directly by writing to these sysfs nodes.

---

## Step 1: Identify Your Battery and Supported Attributes

First, list your power supplies to locate your battery (usually `BAT0`, `BAT1`, or `BATT`):
```bash
ls /sys/class/power_supply/
```

Check what charging threshold files are supported by your kernel and EC:
```bash
ls /sys/class/power_supply/BAT0/*threshold*
```

Depending on the manufacturer driver, you will typically find:

| Node | Purpose | Common Vendors |
| :--- | :--- | :--- |
| `charge_control_end_threshold` | Stops charging at this percentage (e.g., 85 or 80) | ThinkPad (`thinkpad_acpi`), ASUS (`asus_wmi`), Framework, Huawei |
| `charge_control_start_threshold` | Starts charging only if battery drops below this percentage (e.g., 75) | ThinkPad, System76 |
| `charge_stop_threshold` / `charge_start_threshold` | Older naming convention for the above | Older ThinkPads |
| `conservation_mode` | Capping charge at ~80% (1 = enabled, 0 = disabled) | Lenovo IdeaPad / LOQ / Legion (`ideapad_laptop`) |

---

## Step 2: Set the Limit Manually

Because `/sys` is a virtual filesystem owned by root, standard redirection with `sudo echo` will fail due to shell permission rules. Use `tee`:

To cap charging at 85%:
```bash
echo 85 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
```

Or 80%:
```bash
echo 80 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
```

If your laptop also supports a start threshold (useful to prevent micro-charging cycles between 79% and 80%):
```bash
echo 75 | sudo tee /sys/class/power_supply/BAT0/charge_control_start_threshold
```

Verify that the value was written:
```bash
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
```

---

## Step 3: Make the Setting Persistent Across Reboots

Files in `/sys` reset on every system reboot. To make the threshold persistent across reboots, use a systemd one-shot service:

### Option A: The archConfig Standard Setup (Recommended)
This repository installs a dedicated script at `/usr/local/bin/set-battery-limit.sh` with auto-detection for standard sysfs thresholds (`charge_control_end_threshold`), legacy ThinkPad nodes, and Lenovo IdeaPad `conservation_mode`:
```bash
# Configurable via BATTERY_LIMIT env var, /etc/default/battery-limit, or CLI argument:
BATTERY_LIMIT="${1:-${BATTERY_LIMIT:-80}}"
```

And installs `/etc/systemd/system/battery-limit.service`:
```ini
[Unit]
Description=Set Battery Charging Limit
After=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
EnvironmentFile=-/etc/default/battery-limit
ExecStart=/usr/local/bin/set-battery-limit.sh

[Install]
WantedBy=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now battery-limit.service
```

### Option B: Standalone Inline Service Unit
Alternatively, create `/etc/systemd/system/battery-threshold.service`:
```ini
[Unit]
Description=Set battery charge limit
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/bin/sh -c 'echo 85 > /sys/class/power_supply/BAT0/charge_control_end_threshold'

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now battery-threshold.service
```

---

## Step 4: Deep Sleep (S3 Suspend-to-RAM) Optimization

Modern laptops often default to `s2idle` (modern standby), which drains significant battery while suspended in a backpack or overnight.

To switch the kernel's default sleep mode to `deep` (S3 Suspend-to-RAM) via GRUB:
```bash
# Run iff GRUB / grubby is available:
if command -v grubby >/dev/null 2>&1 && { [ -d /boot/grub ] || [ -d /boot/grub2 ] || command -v grub-mkconfig >/dev/null 2>&1 || command -v grub2-mkconfig >/dev/null 2>&1; }; then
    sudo grubby --update-kernel=ALL --args="mem_sleep_default=deep"
fi
```

Verify supported and active sleep modes:
```bash
cat /sys/power/mem_sleep
# Expected output showing deep active:
# s2idle [deep]
```

---

## Troubleshooting & Device Quirks

- **Permission Denied / No such file:**
  If no `*threshold*` files exist under `/sys/class/power_supply/BAT*`, your laptop hardware, embedded controller, or kernel ACPI driver does not expose charge control through the standard sysfs interface.
- **Lenovo IdeaPad / LOQ / Legion Models:**
  Unlike ThinkPads, Lenovo IdeaPad laptops (running the `ideapad_laptop` driver) do not expose charge thresholds under `/sys/class/power_supply/BAT*/`. Instead, they expose a binary toggle at `/sys/bus/platform/drivers/ideapad_*/{*,*/*}/conservation_mode` or `/sys/devices/platform/VPC*/conservation_mode`. Writing `1` enables conservation mode (capping charge at ~80%).
- **Different Battery Identifier:**
  Some laptops use `BAT1` or `BATT` instead of `BAT0`. The auto-detecting script checks `/sys/class/power_supply/*/charge_control_end_threshold`.
- **Kernel Sleep States:**
  If `/sys/power/mem_sleep` only shows `[s2idle]`, your BIOS/firmware might have S3 sleep disabled or omitted from ACPI DSDT tables. Check BIOS settings for an "OS Type" or "Sleep State" toggle (e.g., "Linux" vs "Windows 10/11").
