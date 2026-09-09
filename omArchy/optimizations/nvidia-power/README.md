# NVIDIA Power Management Optimization ("Hot Backpack" Fix)

This optimization resolves the "hot backpack" problem on laptops with NVIDIA GPUs (such as hybrid Intel + NVIDIA RTX setups).

---

## 🔍 The Problem: "Hot Backpack" Syndrome

When closing the laptop lid, `systemd-logind` initiates a system suspend (`s2idle` / Modern Standby). However, on hybrid Linux systems with NVIDIA GPUs:
1. **Unmanaged VRAM:** If the NVIDIA driver is not instructed to preserve and evacuate video memory, running processes or display servers with allocated VRAM cause suspend routines to fail, hang, or abort.
2. **GPU Stays in D0:** The discrete GPU may fail to enter its low-power power state (`D3cold` / `D3hot`), consuming continuous power (~10W–30W) in a closed bag without fan ventilation.
3. **Ghost Wakeups:** Failing sleep hooks can immediately wake the laptop back up while inside the bag, generating severe heat and draining the battery completely.

---

## 🛠️ The Official Fix

The official NVIDIA Linux solution consists of two coordinated parts:

### 1. Kernel Module Configuration
In `/etc/modprobe.d/nvidia-power-management.conf`:
- `options nvidia NVreg_PreserveVideoMemoryAllocations=1`
  Enables the NVIDIA kernel driver to save and restore video memory allocations across suspend, hibernate, and resume.
- `options nvidia NVreg_TemporaryFilePath=/var/tmp`
  Directs temporary allocation backup files to `/var/tmp` on disk rather than `/tmp` (which is a RAM-backed `tmpfs` with limited space that can easily run out of space when preserving 8GB of VRAM).

### 2. NVIDIA Systemd Sleep Services
The `nvidia-utils` package includes three systemd hook units that orchestrate VRAM preservation with `systemd-suspend` and `systemd-hibernate`:
- `nvidia-suspend.service`: Runs `/usr/bin/nvidia-sleep.sh "suspend"` before systemd suspend.
- `nvidia-hibernate.service`: Runs `/usr/bin/nvidia-sleep.sh "hibernate"` before hibernation.
- `nvidia-resume.service`: Runs `/usr/bin/nvidia-sleep.sh "resume"` after system resume.

> **Note:** These units are enabled *without* `--now`. Running `systemctl start` directly on them would invoke immediate sleep routines.

---

## 🚀 How to Apply

### Automated (All Optimizations)
Run the root setup script from the `optimizations` directory:
```bash
cd ~/archConfig/omArchy/optimizations
./setup.sh
```

### Module-Specific Setup
Run the installer directly from this directory:
```bash
cd ~/archConfig/omArchy/optimizations/nvidia-power
./install.sh
```

---

## 📊 Verification

Check the active status of the modprobe options and systemd services:
```bash
cd ~/archConfig/omArchy/optimizations/nvidia-power
./verify.sh
```
