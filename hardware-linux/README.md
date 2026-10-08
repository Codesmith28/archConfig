# Linux Hardware Optimizations (`hardware-linux/`)

This directory contains unified, cross-distro hardware and power management modules specifically written for **Linux systems** (Fedora, Arch Linux, Ubuntu, OmArchy).

> [!NOTE]
> These modules are strictly Linux-specific (utilizing the Linux kernel sysfs power subsystem, udev event rules, modprobe configuration, eBPF LSM security hooks, and systemd units). They are intentionally separated from macOS setup and generic application dotfiles.

---

## 📂 Architecture & Modules

```
hardware-linux/
├── battery/          # 85% charging cap & deep sleep (S3) threshold control
├── usb-wake/         # USB sleep isolation (Hot backpack mouse/dongle wake block)
├── bluetooth/     # Intel AX211 SCO packet fix (btusb.conf) & pre-sleep audio disconnect
├── rog-nvidia/    # ASUS ROG + NVIDIA RTX D3cold, Cardwire eBPF & debounced switching
└── setup.sh       # Universal master runner with hardware validation & --verify flag
```

---

## 🛠️ Module Breakdown

### 1. `battery/` (Laptop Battery Threshold Control)
* **What it does:** Configures the hardware charging limit (default: 85%) across all supported laptop embedded controllers via `/sys/class/power_supply/BAT*/charge_control_end_threshold`.
* **Hardware support:** ASUS, Lenovo (IdeaPad / Legion conservation mode), ThinkPad, Dell, Framework, LG Gram, Sony Vaio.
* **Component:** Installs `set-battery-limit.sh` to `/usr/local/bin` and enables `battery-limit.service`.

### 2. `usb-wake/` (USB Sleep Isolation / Hot Backpack Fix)
* **What it does:** Disables spurious USB controller and external device wakeup signals in `/proc/acpi/wakeup` and sysfs power attributes before sleep.
* **Benefit:** Prevents accidental wakeups in backpacks caused by wireless mice, dongles, or trackpads while maintaining power button wake.
* **Component:** Installs `isolate-wake.sh` and enables `disable-xhci-wake.service`.

### 3. `bluetooth/` (Intel AX211 SCO Hardware Fix & Audio Sleep Hook)
* **What it does:**
  * Writes `/etc/modprobe.d/btusb.conf` (`options btusb enable_autosuspend=0 force_scofix=1 reset=1`): Resolves Intel AX211 controller firmware buffer misalignment, eliminating `corrupted SCO packet` crashes, audio freezing, and microphone drops during voice calls.
  * Installs `/usr/lib/systemd/system-sleep/bluetooth-sleep.sh`: Pre-disconnects active A2DP audio sessions (OnePlus Nord Buds, AirPods, headphones) before suspend, and re-powers the Bluetooth radio on wake to eliminate deadlocks.
  * Pairs with `core/config/wireplumber/` which enforces mSBC HD Voice, dynamic routing, and immediate 0ms return to high-fidelity AAC stereo after calls.

### 4. `rog-nvidia/` (ASUS ROG + NVIDIA dGPU Optimization)
* **What it does:**
  * Enforces fine-grained `D3cold` (0W idle) and VRAM preservation via `/var/lib/systemd/sleep`.
  * Configures Cardwire eBPF LSM GPU isolation (`Smart` mode on AC, `Integrated` mode on Battery).
  * Automatically unmasks dGPU for external displays (HDMI / Type-C DP).
  * Deploys a 4-second debounced AC/Battery switcher to prevent power thrashing during electrical grid flickers.
* **Hardware guard:** Strictly checks DMI (`ROG/TUF/ASUS`) and discrete NVIDIA GPU presence. Skips automatically on non-matching machines.

---

## 🚀 Execution & Verification

### Run all hardware optimizations:
```bash
cd ~/archConfig/hardware-linux
sudo ./setup.sh
```

### Run a specific module:
```bash
sudo ./setup.sh battery
sudo ./setup.sh rog-nvidia
```

### Inspect active status without root:
```bash
./setup.sh --verify
```
