# Hardware Profile: ASUS ROG + NVIDIA RTX Laptop

This directory contains targeted hardware optimizations for **ASUS ROG & TUF laptops with discrete NVIDIA GeForce RTX graphics** (e.g. ASUS ROG Strix G614JV with Intel Core i7-13650HX + NVIDIA GeForce RTX 4060).

---

## 🎯 Scope & Hardware Guard

Unlike distro-generic dotfiles or base software packages, the scripts in this directory are protected by strict DMI and hardware validation:
1. **DMI Verification:** Confirms `sys_vendor`, `product_family`, and `product_name` match ASUS ROG, Strix, Zephyrus, TUF, Flow, or Scar signatures.
2. **GPU Verification:** Confirms presence of an NVIDIA discrete GPU (via PCI subsystem, Cardwire, kernel driver, or ASUS WMI).

If executed on any non-matching system (e.g., ThinkPad, Framework, MacBook, desktop with AMD GPU, or VM), the setup script automatically exits cleanly without modifying system files.

---

## 🛠️ Architecture Components

| File | Destination | Purpose |
| :--- | :--- | :--- |
| `nvidia-power-management.conf` | `/etc/modprobe.d/` | Configures VRAM preservation, SELinux-compliant sleep backing (`/var/lib/systemd/sleep`), and `NVreg_DynamicPowerManagement=0x02` (D3cold). |
| `81-nvidia-pm-audio.rules` | `/etc/udev/rules.d/` | Runtime power management for the NVIDIA HD Audio Controller (`0x040300`, device `0000:01:00.1`) so audio handles do not block PCIe root port sleep. |
| `power-profile-switch.sh` | `/usr/local/bin/` | Detects AC connection across barrel jack (`ADP0`) and USB-C PD; adjusts Cardwire mode, `powerprofilesctl`, and CPU EPP dynamically. |
| `99-laptop-power-dispatch.rules` | `/etc/udev/rules.d/` | Udev hook triggering `power-profile-switch.sh` on AC plug/unplug events. |
| `setup.sh` | Local runner | Deploys rules, installs and configures `asusctl` and `cardwire` across distros, decommissions deprecated `supergfxctl`, and enables systemd sleep units. |

---

## 🔋 Modern GPU Management Hierarchy: Cardwire (eBPF)

To ensure the RTX dGPU drops into **`D3cold` (0W power draw)** on battery and seamlessly unmasks on AC without reboots or display server restarts, `setup.sh` configures Cardwire as the primary GPU manager:

```
[ Application / Compositor Request ]
                 │
  ┌──────────────▼──────────────┐
  │  Primary: Cardwire (eBPF)   │  ──► Intercepts /dev/dri and /dev/nvidia via LSM hooks
  └──────────────┬──────────────┘      (Returns -ENOENT to background apps; 0W D3cold idle)
                 │ (if unavailable)
  ┌──────────────▼──────────────┐
  │  Fallback: ASUS WMI sysfs   │  ──► /sys/devices/platform/asus-nb-wmi/dgpu_disable
  └─────────────────────────────┘      (Direct ACPI hardware power gate with fuser guard)
```

### Why `supergfxctl` Was Deprecated & Replaced
* **The Legacy Flaw:** `supergfxctl` attempted dynamic PCI bus unbinding and kernel module unloads. This frequently caused kernel deadlocks, display crashes, and **strictly required full session logouts or reboots**. It has been officially deprecated and archived upstream in the ASUS Linux ecosystem.
* **The Cardwire Solution:** `cardwire` (developed by the Open Gaming Collective) uses Linux eBPF Security Module (LSM) hooks. It leaves the hardware and driver untouched, intercepting file operations at the syscall level. When blocked, unprivileged background apps receive `-ENOENT`, allowing the NVIDIA GPU to naturally drop into `D3cold` without restarting Wayland or any applications.

1. **Cardwire (`cardwire` / `cardwired.service`):**
   - In `integrated` mode, blocks background apps from pinging the dGPU. This allows Linux PCI runtime PM to put the RTX card into true `D3cold` (0W draw) without unloading kernel modules or killing the Wayland session.
   - In `smart` mode, permits on-demand dGPU access while keeping idle draw minimized.
   - In `hybrid` mode, unblocks all GPU nodes for full workstation performance.
2. **ASUS WMI Sysfs (`dgpu_disable` Fallback):**
   - If Cardwire is not active, `power-profile-switch.sh` safely uses `/sys/devices/platform/asus-nb-wmi/dgpu_disable` (`1` on battery to sleep dGPU with `fuser` safety guard, `0` on AC to enable).

---

## 💻 Multi-Distro Installation Guide

`setup.sh` automatically detects the host distribution and installs the appropriate packages:

### 1. Fedora Linux
- **ASUS Platform Tools & ROG GUI:** Enabled via the Fedora Copr repository:
  ```bash
  sudo dnf copr enable -y lukenukem/asus-linux
  sudo dnf install -y asusctl asusctl-rog-gui
  sudo systemctl enable --now asusd.service
  ```
- **Cardwire (eBPF):** Installed via Terra DNF repository or GitHub release binaries:
  ```bash
  sudo dnf config-manager --add-repo https://terra.fyralabs.com/terra.repo
  sudo dnf install -y cardwire cardwire-gui
  sudo systemctl enable --now cardwired.service
  ```
- **Decommission Legacy supergfxctl:**
  ```bash
  sudo systemctl disable --now supergfxd.service 2>/dev/null || true
  sudo systemctl mask supergfxd.service
  ```

### 2. Arch Linux & OmArchy
- **ASUS Platform Tools, ROG GUI & Cardwire:**
  ```bash
  yay -S asusctl asusctl-rog-gui cardwire-bin
  sudo systemctl enable --now asusd.service cardwired.service
  ```

### 3. Ubuntu / Debian
- **ASUS Platform Tools:**
  - Community PPA (supported releases):
    ```bash
    sudo add-apt-repository -y ppa:mitchellaugustin/asusctl
    sudo apt update && sudo apt install asusctl
    sudo systemctl enable --now asusd.service
    ```
  - Building from source (if PPA unavailable):
    ```bash
    sudo apt install -y build-essential cmake clang libclang-dev libudev-dev pkg-config git
    git clone https://gitlab.com/asus-linux/asusctl.git /tmp/asusctl && cd /tmp/asusctl && make && sudo make install
    sudo systemctl enable --now asusd.service
    ```
- **Cardwire:** Installed directly via the official `.deb` package release:
  ```bash
  curl -sL https://github.com/OpenGamingCollective/cardwire/releases/latest/download/cardwire_<version>_amd64.deb -o /tmp/cardwire.deb
  sudo dpkg -i /tmp/cardwire.deb || sudo apt-get install -f -y /tmp/cardwire.deb
  sudo systemctl enable --now cardwired.service
  ```

---

## 🔒 ACPI Storm Prevention: `asusd.ron` Configuration

To prevent race conditions and event loops between `asusd` and `power-profile-switch.sh`, `setup.sh` enforces the following settings in `/etc/asusd/asusd.ron`:
```ron
(
    change_platform_profile_on_battery: false,
    change_platform_profile_on_ac: false,
    platform_profile_linked_epp: false,
)
```
Disabling internal profile switching inside `asusd` guarantees that udev-triggered power dispatching remains centralized in `power-profile-switch.sh`, eliminating ACPI event floods and stuttering on power detachment.

---

## 🎮 Command Quick Reference

### Cardwire (eBPF GPU Manager)
```bash
# Query active mode
cardwire get

# List GPU devices and eBPF block status
cardwire list

# Plugged into AC: Dynamic on-demand discrete acceleration
cardwire set smart

# Running on Battery: Total dGPU isolation behind eBPF wall (0W idle)
cardwire set integrated

# Workstation / External Display: Unmask all nodes for Wayland PRIME
cardwire set hybrid

# Launch a specific app with discrete GPU unmasked
cardwire launch <binary>
```

### asusctl (ASUS Hardware & Lighting)
```bash
# Display version and hardware info
asusctl info

# Query and switch fan/power profiles
asusctl profile list
asusctl profile get
asusctl profile set Quiet
asusctl profile set Balanced
asusctl profile set Performance
asusctl profile next

# Set battery charge limit (e.g., 80%)
asusctl battery limit 80
asusctl battery info

# Control keyboard backlight brightness
asusctl leds get
asusctl leds set <off|low|med|high>
asusctl leds next

# Launch ASUS ROG Control Center GUI
rog-control-center
```

---

## 🚀 Execution & Verification

To run this hardware profile and deploy all optimizations:
```bash
sudo ./setup.sh
```

To verify status at any time without waking the dGPU:
```bash
./setup.sh --verify
```
