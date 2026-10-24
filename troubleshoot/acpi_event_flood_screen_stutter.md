# Troubleshooting: ACPI Event Flood, TuneD-PPD Oscillation & Display Stutter

## Problem Overview

On modern gaming and hybrid laptops (such as the **ASUS ROG Strix G614JV** with **Intel Core i7-13650HX** and **NVIDIA GeForce RTX 4060 Laptop GPU** running Fedora Linux / KDE Plasma 6 Wayland), plugging or unplugging the AC adapter, switching battery states, or toggling power profiles can trigger:
1. **Severe Screen Stuttering & Cursor Freezes**: Wayland compositor page flips stall and drop frames.
2. **ACPI Event Flood**: Thousands of rapid log events in `journalctl`.
3. **ASUS WMI Embedded Controller (EC) Lockups**:
   ```text
   kernel: Failed to notify asus-wmi (retval): 0x1
   kernel: asus 0003:0B05:19B6.0001: Failed to notify asus-wmi: -5
   ```
4. **KWin DRM Atomic Commit Failures**:
   ```text
   kwin_wayland: atomic commit failed: Device or resource busy
   ```

---

## 🔬 Deep Root Cause Analysis via `journalctl` & `tuned-ppd.log`

Forensic analysis of the system logs revealed three interconnected feedback loops:

### 1. The 25–50 Hz TuneD-PPD Profile Oscillation Ping-Pong Loop
Fedora utilizes `tuned-ppd.service` to translate the `power-profiles-daemon` (PPD) D-Bus API to `tuned.service`. Forensic examination of `/var/log/tuned/tuned-ppd.log` uncovered a catastrophic feedback loop:
```text
2026-10-24 21:02:30,724 INFO  tuned.ppd.controller: Setting TuneD profile to 'balanced'
2026-10-24 21:02:30,790 INFO  tuned.ppd.controller: Performance degraded: 
2026-10-24 21:02:30,802 INFO  tuned.ppd.controller: Setting TuneD profile to 'throughput-performance'
2026-10-24 21:02:30,842 INFO  tuned.ppd.controller: Setting TuneD profile to 'powersave'
2026-10-24 21:02:30,884 INFO  tuned.ppd.controller: Setting TuneD profile to 'balanced'
2026-10-24 21:02:30,924 INFO  tuned.ppd.controller: Setting TuneD profile to 'throughput-performance'
2026-10-24 21:02:30,965 INFO  tuned.ppd.controller: Setting TuneD profile to 'powersave'
... (switched 25+ times in a single second!)
```

#### Why Did This Loop Occur?
1. **`no_turbo` PyInotify Trigger**:
   In `/usr/lib/python3.*/site-packages/tuned/ppd/controller.py`:
   ```python
   if os.path.exists(NO_TURBO_PATH) and self._cmd.read_file(NO_TURBO_PATH).strip() == "1":
       performance_degraded = PerformanceDegraded.HIGH_OPERATING_TEMPERATURE
   ```
   When `powersave` is applied, TuneD sets `/sys/devices/system/cpu/intel_pstate/no_turbo` to `1`. `tuned-ppd` monitors this file via `pyinotify`. Upon modification, `check_performance_degraded()` reads `no_turbo=1`, falsely flags `Performance degraded: high-operating-temperature`, and attempts to remediate by setting `powersave` or `balanced`.
2. **ACPI Platform Profile Inotify Buffer Bypass**:
   `tuned-ppd` also watches `/sys/firmware/acpi/platform_profile` via `pyinotify` with a 100ms debounce buffer (`CLOSE_MODIFY_BUFFER = 0.1`). When TuneD writes to `/sys/firmware/acpi/platform_profile`, the asynchronous ACPI evaluation on the ASUS motherboard exceeds 100ms, causing `process_IN_MODIFY` to fire and command another profile switch.
3. **Competing Power Switchers**:
   If an external udev rule, script, or KDE PowerDevil requests `performance` while on battery or while `tuned-ppd` is in `powersave`, both systems ping-pong continuously at hardware bus speed (every 20ms to 40ms).

### 2. ASUS Embedded Controller (EC) Saturation
On every profile change, TuneD writes to `/sys/firmware/acpi/platform_profile`, invoking `asus_wmi_evaluate_method` to update device `0B05:19B6` (the ASUS ROG N-KEY keyboard/hotkey micro-controller).
Flooded with 25 to 50 ACPI transactions per second, the Embedded Controller runs out of buffer space and returns `-EIO` (`-5`):
```text
Oct 24 22:18:20 Tessa kernel: Failed to notify asus-wmi (retval): 0x1
Oct 24 22:18:20 Tessa kernel: asus 0003:0B05:19B6.0001: Failed to notify asus-wmi: -5
```

### 3. DRM Atomic Commit Stalls & PowerDevil `libddcutil` I2C Bus Contention
- **CPU & GPU Clocks in Flux**: Reconfiguring governors, Intel P-State `energy_performance_preference`, and dirty page writebacks across all 20 CPU threads (`cpu0` through `cpu19`) 50 times per second locks kernel memory and PCIe buses, causing KWin Wayland to drop frames (`atomic commit failed: Device or resource busy`).
- **PowerDevil DDC/CI Probing**:
  When power profile changes occur, KDE PowerDevil initializes `libddcutil` to check for external monitors:
  ```text
  org_kde_powerdevil: (i2c_detect_x37) Extra x37 sleep: Sleeping for 400 milliseconds
  org_kde_powerdevil: [ 41543] Watching for display connection changes, poll loop interval = 100 millisec
  ```
  Sending DDC/CI commands across `/dev/i2c-*` to an internal laptop eDP panel blocks the display pipe for 400ms at a time, resulting in prominent micro-stuttering and cursor freezing.

---

## 🛠️ Complete Multi-Layered Remediation

### Layer 1: Debounced, Mutex-Locked Power Dispatcher
Deploy `/usr/local/bin/power-profile-switch.sh` with a strict `flock` mutex, 2-second rail stabilization delay, and pre-flight state deduplication:
```bash
LOCKFILE="/run/power-profile-switch.lock"
exec 200>"$LOCKFILE" 2>/dev/null || exec 200>"/tmp/power-profile-switch.lock"
flock -n 200 || exit 0
sleep 2

# Verify current profile BEFORE issuing a D-Bus write
cur_prof="$(powerprofilesctl get 2>/dev/null || true)"
if [[ "$cur_prof" != "$target_profile" ]]; then
    powerprofilesctl set "$target_profile" 2>/dev/null || true
fi
```

### Layer 2: Specific Udev Power Supply Matching
In `/etc/udev/rules.d/99-laptop-power-dispatch.rules`, match strictly on `ATTR{type}=="Mains"` and `ATTR{type}=="USB"` to completely prevent battery capacity polling events from triggering power state changes:
```udev
ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/local/bin/power-profile-switch.sh --async"
ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="USB", RUN+="/usr/local/bin/power-profile-switch.sh --async"
```

### Layer 3: Disable PowerDevil `libddcutil` I2C Probing on Laptops
Because laptop panel brightness is natively controlled via `/sys/class/backlight/intel_backlight`, DDC/CI probing over `/dev/i2c` is completely redundant.
Create the systemd user override at `~/.config/systemd/user/plasma-powerdevil.service.d/override.conf`:
```ini
[Service]
# Eliminate libddcutil 400ms I2C bus locks and KWin atomic commit stutter on laptops
Environment="POWERDEVIL_NO_DDCUTIL=1"
```
Reload and restart the service:
```bash
systemctl --user daemon-reload
systemctl --user restart plasma-powerdevil.service
```

---

## 📊 Verification & Diagnostics

### 1. Check for Active Profile Oscillation
Verify `tuned-ppd` is quiet and steady:
```bash
tail -n 20 /var/log/tuned/tuned-ppd.log
```
*Expected*: Single clean transitions without oscillating back-and-forth entries.

### 2. Verify PowerDevil libddcutil Suppression
Check recent PowerDevil logs:
```bash
journalctl --user -u plasma-powerdevil.service -n 20 --no-pager
```
*Expected*: Zero entries containing `i2c_detect_x37 Extra x37 sleep` or `libddcutil recheck thread`.

### 3. Check for ACPI / WMI Errors
```bash
journalctl -b 0 | grep -E "Failed to notify asus-wmi|atomic commit"
```
*Expected*: Clean output without repeated entries.
