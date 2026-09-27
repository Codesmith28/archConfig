# Troubleshooting: NVIDIA Suspend Failure & Rapid Battery Drain ("Hot Backpack" / Fake Sleep)

## Symptoms
- The laptop was left for 30–60 minutes with the lid closed or after triggering sleep.
- Battery dropped dramatically (e.g. from **85% down to 56% in 45 minutes**).
- The laptop was hot to the touch inside a bag or on a desk despite being expected to be in `deep` sleep (`s2idle [deep]`).
- The display was black, giving the illusion that the laptop had slept, but internal components remained fully powered.

---

## 🔍 Root Cause Analysis

### 1. The Sleep Cycle Was Never Entered
The system journal reveals that the laptop **never actually slept**. Each time systemd attempted to suspend, it aborted within 2–3 seconds and bounced back awake:
```text
Sep 27 13:48:19 systemd[1]: Starting systemd-suspend.service - System Suspend...
Sep 27 13:48:19 systemd-sleep[1573268]: Performing sleep operation 'suspend'...
Sep 27 13:48:22 systemd-sleep[1573268]: Failed to put system to sleep. System resumed again: Operation not permitted
Sep 27 13:48:22 systemd[1]: systemd-suspend.service: Main process exited, code=exited, status=1/FAILURE
Sep 27 13:48:22 systemd[1]: systemd-suspend.service: Failed with result 'exit-code'.
```

### 2. SELinux Denied NVIDIA Temporary VRAM Allocation
When video memory preservation is enabled (`options nvidia NVreg_PreserveVideoMemoryAllocations=1`), the NVIDIA kernel driver evacuates VRAM to a temporary backing file before powering down the GPU.

In `/etc/modprobe.d/nvidia-power-management.conf`, the backing path was configured as:
```ini
options nvidia NVreg_TemporaryFilePath=/var/tmp
```
Under Fedora / RHEL, SELinux is set to `Enforcing` by default. When `systemd-suspend` invokes `systemd-sleep`, the process runs under the SELinux security context `systemd_sleep_t`. However, `/var/tmp` files are labeled with the generic context `tmp_t`.

SELinux blocks `systemd_sleep_t` from opening or writing files labeled `tmp_t`:
```text
audit: AVC avc: denied { write open } for pid=1573268 comm="systemd-sleep"
       path="/var/tmp/#2742530 (deleted)" dev="nvme0n1p7" ino=2742530
       scontext=system_u:system_r:systemd_sleep_t:s0
       tcontext=system_u:object_r:tmp_t:s0 tclass=file permissive=0
```

### 3. The NVIDIA FBSR Driver Abort
Because the temporary file could not be created (`error -13` = `EACCES` / Permission Denied), the NVIDIA FrameBuffer Save/Restore routine failed:
```text
kernel: NVRM: The temporary file path specified via the NVreg_TemporaryFilePath module parameter could not be opened (error -13).
kernel: NVRM: FBSR: could not reserve space for video memory preservation. Aborting suspend.
kernel: NVRM: nvidia_suspend returned 0x59; aborting suspend.
kernel: NVRM: PM suspend notifier failed: 0x59
```

### 4. Continuous Retry Loop & Thermal Buildup
Because suspend aborted:
1. The machine remained 100% awake with the Intel CPU, RTX 4060 dGPU, and Wi-Fi running.
2. Every 30–60 seconds, GNOME / systemd re-attempted sleep, triggering another failed suspend attempt and CPU spike.
3. With the lid closed, airflow was restricted, trapping heat inside the chassis and burning 29% battery in 45 minutes.

---

## 🛠️ The Fix

### Option A: Immediate Fix Without Rebooting
Because `nvidia.ko` loads `NVreg_TemporaryFilePath` at boot time and sysfs parameter files are read-only at runtime, the running kernel will continue targeting `/var/tmp` until rebooted.

To permit sleep **immediately without restarting**, generate an SELinux policy module from the audit denial log:

```bash
# 1. Generate an SELinux policy allowing systemd_sleep_t to write to tmp_t
journalctl -b 0 -g "denied.*systemd-sleep" | audit2allow -M nvidia_sleep

# 2. Install the compiled policy module
sudo semodule -i nvidia_sleep.pp

# 3. Test sleep immediately
systemctl suspend
```

---

### Option B: Permanent, Clean Solution (Target Directory `/var/lib/systemd/sleep`)
Fedora's standard SELinux policy already provides a pre-authorized context `systemd_sleep_var_lib_t` for `/var/lib/systemd/sleep(/.*)?`. Redirecting NVIDIA's backing files here resolves the issue cleanly at the architectural level without needing custom SELinux exceptions.

#### 1. Create the Directory with Secure Permissions & SELinux Label
```bash
sudo mkdir -p /var/lib/systemd/sleep
sudo chmod 0700 /var/lib/systemd/sleep
sudo restorecon -v /var/lib/systemd/sleep
```

#### 2. Update `/etc/modprobe.d/nvidia-power-management.conf`
Ensure the file contains:
```ini
# Preserve video memory allocations across suspend and hibernate
options nvidia NVreg_PreserveVideoMemoryAllocations=1

# Use /var/lib/systemd/sleep for temporary video memory allocation backing files.
# Avoids /tmp (tmpfs in RAM) and complies with SELinux (systemd_sleep_var_lib_t).
options nvidia NVreg_TemporaryFilePath=/var/lib/systemd/sleep
```

#### 3. Update Initramfs (Dracut)
Rebuild the initramfs so the new module parameter is packaged into early boot:
```bash
sudo dracut -f
```

---

## 🚀 One-Command Automated Setup
The `archConfig` repository includes an automated setup script that applies all these steps:
```bash
cd ~/archConfig/distros/fedora/optimizations/nvidia-power
sudo ./setup.sh
```

To verify the setup:
```bash
./setup.sh --verify
```

---

## 📊 Verification Commands
After applying the fix and testing a suspend cycle (`systemctl suspend` or closing the lid):

1. **Verify Suspend Succeeded:**
   ```bash
   journalctl -b 0 -u systemd-suspend.service --no-pager -n 20
   ```
   *Expected output:* `systemd-suspend.service: Deactivated successfully` and `System returned from sleep state`.

2. **Verify Zero SELinux Denials:**
   ```bash
   journalctl -b 0 -g "denied.*systemd-sleep" --no-pager
   ```
   *Expected output:* No denials found.

3. **Verify NVIDIA VRAM Allocation Parameter:**
   ```bash
   cat /sys/module/nvidia/parameters/NVreg_TemporaryFilePath
   ```
   *Expected output:* `/var/lib/systemd/sleep` (after reboot).
