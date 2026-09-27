# Troubleshooting: NVIDIA Suspend Failure & Rapid Battery Drain ("Hot Backpack" Syndrome)

## Symptoms
- The laptop was left for 30–60 minutes with the lid closed or after triggering sleep.
- Battery dropped dramatically (e.g. from **85% down to 56% in 45 minutes**).
- The laptop chassis became hot to the touch despite expecting `deep` sleep (`s2idle [deep]`).
- The display was black, creating the illusion of sleep, but the system remained powered on.

---

## 🔍 Root Cause Analysis

### 1. The Sleep Cycle Was Aborted Immediately
Systemd logs show that the laptop never entered sleep. The suspend routine aborted within 2.4 seconds and resumed back to full power:
```text
Sep 27 13:48:19 systemd[1]: Starting systemd-suspend.service - System Suspend...
Sep 27 13:48:19 systemd-sleep[1573268]: Performing sleep operation 'suspend'...
Sep 27 13:48:22 systemd-sleep[1573268]: Failed to put system to sleep. System resumed again: Operation not permitted
Sep 27 13:48:22 systemd[1]: systemd-suspend.service: Main process exited, code=exited, status=1/FAILURE
Sep 27 13:48:22 systemd[1]: systemd-suspend.service: Failed with result 'exit-code'.
```

### 2. SELinux Security Policy Denial
When video memory preservation is enabled (`options nvidia NVreg_PreserveVideoMemoryAllocations=1`), the NVIDIA kernel driver evacuates VRAM to a temporary backing file before powering down the GPU.

In `/etc/modprobe.d/nvidia-power-management.conf`, the backing path was configured as:
```ini
options nvidia NVreg_TemporaryFilePath=/var/tmp
```
Under Fedora, SELinux runs in `Enforcing` mode by default. When `systemd-suspend` calls `systemd-sleep`, it executes in the confined domain `systemd_sleep_t`. However, `/var/tmp` files carry the generic context `tmp_t`. SELinux blocks `systemd_sleep_t` from opening or writing files labeled `tmp_t`:
```text
audit: AVC avc: denied { write open } for pid=1573268 comm="systemd-sleep"
       path="/var/tmp/#2742530 (deleted)" dev="nvme0n1p7" ino=2742530
       scontext=system_u:system_r:systemd_sleep_t:s0
       tcontext=system_u:object_r:tmp_t:s0 tclass=file permissive=0
```

### 3. NVIDIA FBSR Driver Abort
Because file creation was denied with error `-13` (`EACCES` / Permission Denied), the NVIDIA FrameBuffer Save/Restore routine failed and returned `0x59`:
```text
kernel: NVRM: The temporary file path specified via the NVreg_TemporaryFilePath module parameter could not be opened (error -13).
kernel: NVRM: FBSR: could not reserve space for video memory preservation. Aborting suspend.
kernel: NVRM: nvidia_suspend returned 0x59; aborting suspend.
kernel: NVRM: PM suspend notifier failed: 0x59
```

### 4. Continuous Loop in a Closed Laptop
Because suspend was aborted:
1. The machine remained wide awake with the Intel CPU, RTX 4060 dGPU, and Wi-Fi active.
2. Every 30–60 seconds, GNOME and systemd retried sleep, repeating the 2-second failure cycle.
3. With the lid closed, airflow was restricted, accumulating heat inside the chassis and burning 29% battery in 45 minutes.

---

## 📚 Authoritative Upstream Documentation

According to the official **[RPM Fusion NVIDIA Documentation](https://rpmfusion.org/Howto/NVIDIA)** and **[Fedora SELinux Policy](https://github.com/fedora-selinux/selinux-policy)**:
- Fedora's default SELinux policy pre-authorizes `systemd-sleep` (`systemd_sleep_t`) to write exclusively into `/var/lib/systemd/sleep` via the file context:
  ```text
  /var/lib/systemd/sleep(/.*)?    system_u:object_r:systemd_sleep_var_lib_t:s0
  ```
- Specifying `/var/tmp` in modprobe configuration triggers SELinux AVC denials because `/var/tmp` is labeled `tmp_t`.
- The canonical, upstream-supported directory for NVIDIA suspend memory dumps on Fedora is `/var/lib/systemd/sleep`.

---

## 🛠️ The Canonical Upstream Fix

### Step 1: Ensure `/var/lib/systemd/sleep` Exists with Secure Permissions
```bash
sudo mkdir -p /var/lib/systemd/sleep
sudo chmod 0700 /var/lib/systemd/sleep
sudo restorecon -v /var/lib/systemd/sleep
```

### Step 2: Configure Modprobe for the Official Path
Update `/etc/modprobe.d/nvidia-power-management.conf` (or run `sudo ./setup.sh` in `distros/fedora/optimizations/nvidia-power/`):
```ini
# Preserve video memory allocations across suspend and hibernate
options nvidia NVreg_PreserveVideoMemoryAllocations=1

# Use the SELinux-authorized systemd sleep directory on disk
options nvidia NVreg_TemporaryFilePath=/var/lib/systemd/sleep
```

### Step 3: Rebuild Initramfs and Reboot
Because `NVreg_TemporaryFilePath` is loaded into kernel space during early boot, rebuild the initramfs using dracut:
```bash
sudo dracut -f
sudo reboot
```

---

## 📊 Verification Commands

After rebooting and testing a suspend cycle (`systemctl suspend` or closing the lid):

1. **Verify Suspend Succeeded:**
   ```bash
   journalctl -b 0 -u systemd-suspend.service --no-pager -n 20
   ```
   *Expected output:* `systemd-suspend.service: Deactivated successfully` and `System returned from sleep state`.

2. **Verify Zero SELinux Denials:**
   ```bash
   journalctl -b 0 -g "denied.*systemd-sleep" --no-pager
   ```
   *Expected output:* No entries.

3. **Verify Kernel Parameter:**
   ```bash
   cat /sys/module/nvidia/parameters/NVreg_TemporaryFilePath
   ```
   *Expected output:* `/var/lib/systemd/sleep`.
