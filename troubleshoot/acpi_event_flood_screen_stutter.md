# Troubleshooting: ACPI Event Flood, Violent dGPU PCIe Drops & Display Stutter

## Problem Overview

On modern gaming and hybrid laptops (such as the **ASUS ROG Strix G614JV** with **Intel Core i7-13650HX** and **NVIDIA GeForce RTX 4060 Laptop GPU** running Fedora Linux / GNOME & KDE Wayland), unplugging the AC power source triggers:
1. **Severe Screen Stuttering & Cursor Freezes**: Wayland compositor page flips stall and drop frames for several seconds.
2. **dGPU Vanishing from PCI Bus**: The NVIDIA discrete GPU completely disappears from `lspci` upon reconnection.
3. **Kernel NVRM Driver Panics & PCIe AER Errors**:
   ```text
   kernel: NVRM: nvAssertOkFailedNoLog: Assertion failed: Invalid data passed [NV_ERR_INVALID_DATA] (0x00000025) returned from PlatformRequestHandler failed to get platform power mode from SBIOS @ platform_request_handler_ctrl.c:2118
   kernel: NVRM: nvAssertOkFailedNoLog: Assertion failed: Invalid data passed [NV_ERR_INVALID_DATA] (0x00000025) returned from PshareStatus @ platform_request_handler_ctrl.c:1505
   ```
4. **ASUS WMI Embedded Controller (EC) Buffer Overflows**:
   ```text
   kernel: Failed to notify asus-wmi (retval): 0x1
   kernel: asus 0003:0B05:19B6.0001: Failed to notify asus-wmi: -5
   asusd[1371]: [ERROR asusd::asus_armoury] Failed to set charge_mode: std::io error: Permission denied (os error 13)
   ```
5. **Self-Referential Udev Event Storms**: Rapid succession of power supply uevents flooding the system bus.

---

## 🔬 Forensic Root Cause Analysis

System log inspection (`journalctl -b`, `journalctl -k -b`, `dmesg`), hardware interrupts, sysfs nodes, and udev dispatch traces pinpoint four interlocking root causes across hardware, kernel drivers, and background daemons:

### 1. Violent dGPU Power Drop via ASUS WMI `dgpu_disable`
* **Root Mechanism:**
  1. Cardwire manages GPU isolation via eBPF LSM filters (`cardwire set integrated` on battery), cleanly blocking user applications from opening `/dev/nvidia*` so the GPU enters runtime PM `D3cold` (0W power consumption).
  2. However, `/usr/local/bin/power-profile-switch.sh` retained a legacy fallback block that checked `fuser /dev/nvidia*`. Because Cardwire successfully kept processes off the dGPU, `fuser` returned empty, causing the script to unconditionally execute:
     ```bash
     echo 1 > /sys/devices/platform/asus-nb-wmi/dgpu_disable
     ```
  3. Setting `dgpu_disable=1` invokes the ASUS ACPI firmware method that abruptly cuts physical PCIe power to the PEG root port (`0000:00:01.0`) and the RTX 4060 dGPU (`0000:01:00.0`).
  4. The proprietary NVIDIA kernel modules (`nvidia_drm`, `nvidia_modeset`, `nvidia`) were actively loaded and attached. The sudden hardware removal caused kernel driver threads to panic with `NV_ERR_INVALID_DATA`, stalled DRM page flips, locked the PCIe bus (triggering PCIe AER errors on the NVMe SSD `0000:6e:00.0`), and froze the screen.
  5. Upon AC reconnect, `echo 0 > dgpu_disable` re-energized the port, but Linux does not automatically detect the resurrected device without an explicit PCI bus rescan (`echo 1 > /sys/bus/pci/rescan`), leaving the dGPU permanently missing from `lspci`.

### 2. Multi-Daemon Profile Race & False Degradation Alerts (`tuned-ppd`)
* **Root Mechanism:**
  1. `/etc/tuned/ppd.conf` had `battery_detection=true` enabled.
  2. When the power adapter was unplugged, UPower emitted a DC transition. `tuned-ppd` immediately instructed TuneD to switch to `balanced-battery`.
  3. Simultaneously, udev rule `99-laptop-power-dispatch.rules` ran `power-profile-switch.sh`, which requested `power-saver` (`powersave`).
  4. In `powersave`, TuneD sets `/sys/devices/system/cpu/intel_pstate/no_turbo` to `1`. `tuned-ppd` monitors `no_turbo` via `pyinotify`. Upon modification, `check_performance_degraded()` falsely flagged:
     `Performance degraded: high-operating-temperature`.
  5. Both services sequentially hammered `/sys/firmware/acpi/platform_profile`.
  6. `asusd` watches `platform_profile` via inotify. Every change triggered `asusd` to write 3 fan curve tables (CPU, GPU, MID = 24 sysfs writes) into ACPI WMI sysfs, overwhelming the ASUS Embedded Controller (`0B05:19B6`) and causing I2C/SMBus controller starvation.

### 3. Read-Only Sysfs Spam in ASUS Daemon (`asusd.ron`)
* **Root Mechanism:**
  1. `/etc/asusd/asusd.ron` contained `armoury_settings: { ChargeMode: 1 }`.
  2. On modern Linux kernels (Linux 6.x and 7.x), `/sys/devices/platform/asus-nb-wmi/charge_mode` is exposed as read-only (`-r--r--r--`).
  3. `asusd` attempted to write to this node on every profile transition, producing recurring error cascades:
     ```text
     asusd[1371]: [ERROR asusd::asus_armoury] Failed to set charge_mode: std::io error: Permission denied (os error 13)
     asusd[1371]: [INFO  asusd::asus_armoury] Restored armoury setting for charge_mode = 1
     ```

### 4. Self-Referential Battery Threshold Loops (`90-battery-limit.rules`)
* **Root Mechanism:**
  1. `/etc/udev/rules.d/90-battery-limit.rules` matched `KERNEL=="BAT[0-9]*|ADP[0-9]*|AC*|ucsi*"`.
  2. When triggered, it executed `/usr/local/bin/set-battery-limit.sh`, which wrote `80` to `/sys/class/power_supply/BAT0/charge_control_end_threshold`.
  3. Writing to `charge_control_end_threshold` emitted a new `ACTION=change` uevent on `BAT0`, which matched the rule again, initiating a self-referential loop.

---

## 🛠️ Multi-Layered Permanent Remediation

### Layer 1: Safe eBPF GPU Management in `power-profile-switch.sh`
* **Action:**
  - Removed all `echo 1 > dgpu_disable` writes from `set_gpu_posture()`.
  - Let Cardwire eBPF exclusively govern GPU posture (`cardwire set integrated` on battery, `cardwire set smart` on AC). Cardwire’s eBPF filter naturally guides the GPU into `D3cold` (0W) without PCIe disconnection.
  - Guarded `dgpu_disable` to ensure it is always `0` (powered).
  - Automatically invoke PCI bus rescan (`echo 1 > /sys/bus/pci/rescan`) if the dGPU is missing from `lspci`.

```bash
set_gpu_posture() {
    local state="$1" # "ac" or "battery"

    # 1. Cardwire eBPF controller
    if command -v cardwire >/dev/null 2>&1; then
        if [[ "$state" == "ac" ]]; then
            cardwire set smart 2>/dev/null || true
        else
            cardwire set integrated 2>/dev/null || true
        fi
    fi

    # 2. Guard ASUS WMI dgpu_disable sysfs node
    local dgpu_node="/sys/devices/platform/asus-nb-wmi/dgpu_disable"
    if [[ -f "$dgpu_node" && -w "$dgpu_node" ]]; then
        local cur_val="$(cat "$dgpu_node" 2>/dev/null || true)"
        if [[ "$cur_val" != "0" ]]; then
            echo 0 > "$dgpu_node" 2>/dev/null || true
        fi
    fi

    # 3. Rescan PCI bus if dGPU is absent from sysfs/lspci
    if [[ -w /sys/bus/pci/rescan ]]; then
        if ! lspci -d 10de: >/dev/null 2>&1; then
            echo 1 > /sys/bus/pci/rescan 2>/dev/null || true
        fi
    fi
}
```

### Layer 2: Harmonize `tuned-ppd.conf`
* **Action:**
  - Configure `/etc/tuned/ppd.conf` with:
    ```ini
    battery_detection=false
    sysfs_acpi_monitor=false
    ```
  - Eliminates autonomous profile switches on DC events and suppresses false `no_turbo=1` performance degradation triggers.

### Layer 3: Neutralize Read-Only `ChargeMode` in `asusd.ron`
* **Action:**
  - In `/etc/asusd/asusd.ron`, remove `ChargeMode: 1` from `armoury_settings` to eliminate `Permission denied (os error 13)` error spam and unnecessary EC transactions.

### Layer 4: Idempotent Battery Limit & Strict Udev Matching
* **Action:**
  - In `hardware-linux/battery/90-battery-limit.rules`, restrict matching strictly to `ATTR{type}=="Mains"` and `ATTR{type}=="USB"` with `ENV{POWER_SUPPLY_ONLINE}=="?*"`. BAT0 internal events will never re-trigger the rule.
  - In `hardware-linux/battery/set-battery-limit.sh`, add a fast-path pre-flight check:
    ```bash
    current_limit="$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo "")"
    if [ "$current_limit" = "$BATTERY_LIMIT" ]; then
        exit 0
    fi
    ```
    If the threshold is already active, the script immediately exits without performing any D-Bus or sysfs I/O.

---

## 📊 Verification & Diagnostics

### 1. Verify Discrete GPU Posture & Bus Presence
```bash
# Verify NVIDIA GPU is visible on PCI bus
lspci -nnk -d 10de:

# Verify Cardwire mode
cardwire get

# Verify ASUS dGPU sysfs node is NOT disabling the port (must be 0)
cat /sys/devices/platform/asus-nb-wmi/dgpu_disable
```
*Expected*: NVIDIA RTX 4060 present in `lspci`, Cardwire reports `Integrated` (battery) or `Smart` (AC), `dgpu_disable` is `0`.

### 2. Verify TuneD-PPD & ASUS Stability
```bash
# Check TuneD PPD configuration
grep -E "battery_detection|sysfs_acpi_monitor" /etc/tuned/ppd.conf

# Check asusd configuration for armoury settings
grep -A 2 "armoury_settings" /etc/asusd/asusd.ron

# Verify absence of asusd error spam in systemd journal
journalctl -u asusd.service -n 30 --no-pager | grep -i "permission denied"
```
*Expected*: `battery_detection=false`, `sysfs_acpi_monitor=false`, no `ChargeMode` in `armoury_settings`, 0 permission denied errors.

### 3. Verify Battery Threshold Idempotence
```bash
# Test manual execution: must immediately exit without writing to hardware
/usr/local/bin/set-battery-limit.sh
```
*Expected Output*: `Charging limit is already set to 80%. No action required.`

### 4. Verify ACPI & WMI Logs on Unplug
```bash
journalctl -b 0 | grep -E "nvAssertOkFailed|Failed to notify asus-wmi|atomic commit"
```
*Expected Output*: Zero recurring entries during AC disconnect transitions.
