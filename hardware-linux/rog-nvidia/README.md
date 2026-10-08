# Hardware Profile: ASUS ROG + NVIDIA RTX Laptop

This directory contains targeted hardware optimizations for **ASUS ROG & TUF laptops with discrete NVIDIA GeForce RTX graphics** (e.g. ASUS ROG Strix G614JV with Intel Core i7-13650HX + NVIDIA GeForce RTX 4060).

---

## 🎯 Scope & Hardware Guard

Unlike distro-generic dotfiles or base software packages, the scripts in this directory are protected by strict DMI and hardware validation:
1. **DMI Verification:** Confirms `sys_vendor`, `product_family`, and `product_name` match ASUS ROG, Strix, Zephyrus, TUF, or Flow signatures.
2. **GPU Verification:** Confirms presence of an NVIDIA discrete GPU (via PCI subsystem, Cardwire, or kernel driver).

If executed on any non-matching system (e.g., ThinkPad, Framework, MacBook, desktop with AMD GPU, or VM), the setup script automatically exits cleanly without modifying system files.

---

## 🛠️ Architecture Components

| File | Destination | Purpose |
| :--- | :--- | :--- |
| `nvidia-power-management.conf` | `/etc/modprobe.d/` | Configures VRAM preservation, SELinux-compliant sleep backing (`/var/lib/systemd/sleep`), and `NVreg_DynamicPowerManagement=0x02` (D3cold). |
| `81-nvidia-pm-audio.rules` | `/etc/udev/rules.d/` | Runtime power management for the NVIDIA HD Audio Controller (`0x040300`, device `0000:01:00.1`) so audio handles do not block PCIe root port sleep. |
| `power-profile-switch.sh` | `/usr/local/bin/` | Detects AC connection across barrel jack (`ADP0`) and USB-C PD; adjusts Cardwire mode, `powerprofilesctl`, and CPU EPP dynamically. |
| `99-laptop-power-dispatch.rules` | `/etc/udev/rules.d/` | Udev hook triggering `power-profile-switch.sh` on AC plug/unplug events. |
| `setup.sh` | Local runner | Deploys rules, configures Cardwire daemon policies, enables systemd sleep units, and verifies status across Fedora, Arch, and Ubuntu. |

---

## 🎮 Cardwire Operational Postures

```bash
# Check current active mode
cardwire get

# List GPU nodes and eBPF block status
cardwire list

# Plugged into AC: On-demand discrete GPU acceleration
cardwire set smart

# Running on Battery: Total dGPU isolation behind eBPF wall (0W idle)
cardwire set integrated

# Workstation / External Display: Unmask all nodes for Wayland PRIME
cardwire set hybrid

# Run an application explicitly on the RTX 4060
cardwire launch <binary>
```

---

## 🚀 Execution & Verification

To run this hardware profile:
```bash
sudo ./setup.sh
```

To verify status at any time without waking the dGPU:
```bash
./setup.sh --verify
```
