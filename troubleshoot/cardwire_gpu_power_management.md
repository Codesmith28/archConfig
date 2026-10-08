# Troubleshooting & Guide: Cardwire GPU Isolation, D3cold & Power Switching

## Overview
This runbook documents the configuration, pitfalls, and verified setup for hybrid GPU power management on modern Intel + NVIDIA laptops (specifically validated on the **ASUS ROG Strix G614JV** with **Intel Core i7-13650HX** and **NVIDIA GeForce RTX 4060 Laptop GPU** running **Fedora 44 / GNOME 50.5 Wayland**).

---

## 🔍 Critical Pitfalls in Generic Guides & Manuals

When following generic manuals or forum guides for NVIDIA power management and Cardwire, several hardware- and distro-specific issues arise:

### 1. Cardwire CLI Subcommand Syntax Drift
- **Common Error in Guides:**
  ```bash
  cardwire mode integrated   # ❌ FAILS with "error: unrecognized subcommand 'mode'"
  cardwire mode smart        # ❌ FAILS
  ```
- **The Reality:** In `cardwire` (Open Gaming Collective, v0.12+), mode switching uses `set` and inspection uses `get`:
  ```bash
  cardwire set integrated    # ✅ Valid
  cardwire set smart         # ✅ Valid
  cardwire set hybrid        # ✅ Valid
  cardwire get               # ✅ Returns current mode
  cardwire list              # ✅ Shows GPU table and eBPF block state
  ```

### 2. Hardcoded AC Power Supply Paths (`ADP0` vs `AC0`)
- **Common Error in Guides:**
  ```bash
  STATUS=$(cat /sys/class/power_supply/AC0/online 2>/dev/null || cat /sys/class/power_supply/ADP1/online 2>/dev/null)
  ```
- **The Reality on ASUS ROG Laptops:**
  - The proprietary barrel AC charger is registered as `/sys/class/power_supply/ADP0` (not `AC0` or `ADP1`).
  - USB-C Power Delivery chargers register as `/sys/class/power_supply/ucsi-source-psy-USBC000:001`.
  - Checking hardcoded names results in empty strings, breaking integer comparisons (`[ "" -eq 1 ]`).
  - **The Fix:** Universally evaluate any online supply using:
    ```bash
    if grep -qs 1 /sys/class/power_supply/*/online; then
        # Running on AC power (barrel charger or USB-C PD)
    ```

### 3. Modprobe Config Conflicts & SELinux "Hot Backpack" Regressions
- **Common Error in Guides:**
  Blindly creating `/etc/modprobe.d/nvidia-pm.conf` or setting `NVreg_TemporaryFilePath=/var/tmp`.
- **The Reality:**
  Fedora's SELinux policy enforces strict write confinement on `systemd_sleep_t`. As documented in [nvidia_selinux_suspend_battery_drain.md](file:///home/codesmith28/archConfig/troubleshoot/nvidia_selinux_suspend_battery_drain.md), writing sleep memory dumps anywhere other than `/var/lib/systemd/sleep` causes immediate suspend abortions and drains the battery rapidly in backpacks.
  - **The Fix:** Preserve `NVreg_TemporaryFilePath=/var/lib/systemd/sleep` and `NVreg_PreserveVideoMemoryAllocations=1` while adding `NVreg_DynamicPowerManagement=0x02` and `nvidia-drm modeset=1` in a single unified configuration file (`/etc/modprobe.d/nvidia-power-management.conf`).

### 4. PCI Audio Controller (`0x040300`) Missing from Runtime PM
- Fedora's upstream `/usr/lib/udev/rules.d/80-nvidia-pm.rules` configures runtime PM for VGA (`0x030000`) and 3D (`0x030200`) controllers, but omits the companion NVIDIA HD Audio Controller (`0x040300`, device `0000:01:00.1`). Adding an explicit udev rule for `0x040300` prevents audio handles from blocking the PCIe root port from sleeping.

---

## ⚙️ Architecture: How Cardwire Works with NVIDIA D3cold

```
[ Unprivileged Apps: Browsers, Electron, Wayland Compositor ]
                          │
                          ▼ (attempts open / ioctl on /dev/dri/card* or /dev/nvidia*)
       ┌────────────────────────────────────────────────────────┐
       │                Cardwire eBPF LSM Filter                │
       └────────────────────────────────────────────────────────┘
                 │                                    │
    Mode: Integrated / Smart              Mode: Hybrid / cardwire launch
                 │                                    │
                 ▼                                    ▼
       [ Access BLOCKED ]                     [ Access PERMITTED ]
                 │                                    │
        GPU stays in D3cold                   GPU powers up to D0
          (0W power draw)                      (Full CUDA / 3D Compute)
```

1. **Cardwire** runs as `cardwired.service` and attaches eBPF LSM security hooks to intercept device calls to `/dev/dri/renderD*`, `/dev/dri/card*`, and `/dev/nvidia*`.
2. When in **`integrated`** mode or **`smart`** mode (idle):
   - Background processes trying to query GPU capabilities (e.g., Chrome, Discord, Slack, Ghostty) receive permission-denied / device-masked signals.
   - Zero handles remain on the NVIDIA driver stack.
   - The NVIDIA driver and Linux PCI subsystem power down the RTX 4060 into **`D3cold`** (0W).
3. When in **`hybrid`** mode or executed via `cardwire launch <cmd>`:
   - The target PID and child processes are granted access through the eBPF filter.
   - The PCI bridge link trains up and the GPU enters **`D0`** instantly without requiring a display server restart or session logout.

---

## 🛠️ Step-by-Step Implementation

### Step 1: Verify & Consolidate Modprobe Options
Ensure `/etc/modprobe.d/nvidia-power-management.conf` contains:
```ini
# Preserve video memory allocations across suspend and hibernate
options nvidia NVreg_PreserveVideoMemoryAllocations=1

# Universal SELinux-compliant sleep backing path
options nvidia NVreg_TemporaryFilePath=/var/lib/systemd/sleep

# Enforce fine-grained dynamic power management (D3cold)
options nvidia "NVreg_DynamicPowerManagement=0x02"

# Enable DRM kernel modesetting
options nvidia-drm modeset=1
```

### Step 2: Configure Cardwire Native Auto-Switching
Cardwire includes built-in daemon-level power and external display listeners. Activate them via CLI:
```bash
cardwire config battery-auto-switch true
cardwire config battery-auto-switch-mode integrated
cardwire config external-display-auto-switch true
cardwire config save
```

### Step 3: Install Udev Rules & Power Profile Dispatcher
Automate power profiles and CPU energy performance preference (EPP) using the provided scripts in `hardware/rog-nvidia/`:
```bash
cd ~/archConfig/hardware/rog-nvidia
sudo ./setup.sh
```
This deploys:
- `/usr/local/bin/power-profile-switch.sh`: Toggles `powerprofilesctl` (`performance` on AC vs `power-saver` on Battery) and sets CPU EPP (`balance_performance` vs `power`).
- `/etc/udev/rules.d/81-nvidia-pm-audio.rules`: Runtime PM for NVIDIA Audio (`0x040300`).
- `/etc/udev/rules.d/99-laptop-power-dispatch.rules`: Triggers profile switching on AC events.

### Step 4: Verify Intel QuickSync Hardware Video Decoding
Confirm `libva-intel-media-driver` is active so browser and media playback runs entirely on the Intel UHD iGPU without engaging the dGPU:
```bash
sudo dnf install -y libva-utils
vainfo --display drm --device /dev/dri/renderD128
```
Look for `VAProfileAV1Profile0`, `VAProfileVP9Profile2`, `VAProfileH264*` with `VAEntrypoint_VLD`.

#### Browser Configuration:
- **Firefox:**
  Navigate to `about:config`:
  - `media.ffmpeg.vaapi.enabled` = `true`
  - `media.hardware-video-decoding.force-enabled` = `true`
- **Brave / Chromium:**
  Launch with Wayland flags or configure in `~/.config/brave-flags.conf`:
  ```text
  --enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoDecoder
  --ozone-platform=wayland
  ```

---

## 📊 Verification & Diagnostics

### 1. Cardwire GPU State Check
```bash
cardwire list
```
*Expected output when idle or on battery:*
```text
ID  NAME                                PCI           RENDER      CARD   DEFAULT DISCRETE  BLOCKED
--  ----------------------------------  ------------  ----------  -----  -------  -------  -------
0   Intel                               0000:00:02.0  renderD128  card1  (*)      ( )      false  
1   NVIDIA GeForce RTX 4060 Laptop GPU  0000:01:00.0  renderD129  card0  ( )      (*)      true   
```

### 2. Inspecting Daemon Logs
```bash
journalctl -u cardwired -n 20 --no-pager
```
*Look for:* `NVIDIA GeForce RTX 4060 Laptop GPU: Power state changed: D3Cold` and processes being blocked.

### 3. Measuring Battery Drain Without Waking the dGPU
> **WARNING:** Do NOT execute `nvidia-smi` while operating on battery. Querying the NVIDIA driver forces the card into `D0` and draws 15W–25W for several minutes.

Read the hardware battery gauge directly:
```bash
# Power draw in microwatts (e.g. 9500000 = ~9.5W)
cat /sys/class/power_supply/BAT0/power_now
```
Expected idle discharge on the ROG Strix G614JV with 165 Hz display and iGPU decode is **8W to 12W**.
