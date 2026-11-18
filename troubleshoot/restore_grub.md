# Troubleshooting: Restoring GRUB & Fixing Dual-Boot

## 1. GRUB Not Showing Up (Direct Boot to Windows / BIOS)

When a Windows update or BIOS reset overwrites the EFI boot order or deletes the Linux NVRAM entry:

### Quick Fix (from Linux Live USB or Chroot)

```bash
# 1. Mount your root and EFI partition (adjust nvme0n1pX to match your disks)
sudo mount /dev/nvme0n1p2 /mnt
sudo mount /dev/nvme0n1p1 /mnt/boot  # or /mnt/boot/efi

# 2. Enter chroot (Arch: arch-chroot /mnt ; Fedora/Ubuntu: arch-chroot or bind mounts)
arch-chroot /mnt

# 3. Run the automated restore script:
bash /home/codesmith28/archConfig/troubleshoot/restoreGrub.sh
```

### Manual Commands
```bash
pacman -Sy grub efibootmgr dosfstools mtools
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

---

## 2. Windows Missing from the GRUB Menu

If Linux boots fine but the Windows option is missing from dual-boot:

1. Install `os-prober`:
   * **Arch**: `sudo pacman -S os-prober`
   * **Fedora**: `sudo dnf install os-prober`
   * **Ubuntu**: `sudo apt install os-prober`

2. Enable `os-prober` in `/etc/default/grub`:
   ```bash
   echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub
   ```
   *(Or pass `--enable-os-prober` when running `restoreGrub.sh`). Note: this is only required for multi-boot/Windows detection and is omitted by default to keep single-boot configurations clean.*

3. Regenerate the GRUB config:
   * **Arch / Ubuntu**:
     ```bash
     sudo grub-mkconfig -o /boot/grub/grub.cfg
     ```
   * **Fedora (UEFI)**:
     ```bash
     sudo grub2-mkconfig -o /etc/grub2-efi.cfg
     ```


---

## 3. High-Resolution Display & UEFI GOP Auto-Resolution

### Problem
When `GRUB_TERMINAL_OUTPUT="console"` is active or conflicting font overrides exist, GRUB falls back to 80x25 text console mode. Furthermore, hardcoding fixed resolutions can cause display initialization failures across external monitors and docks.

### Automated Setup & Verification
```bash
# Check current GRUB display status
./troubleshoot/restoreGrub.sh --verify

# Apply clean UEFI GOP auto-resolution to /etc/default/grub and regenerate grub.cfg:
sudo ./troubleshoot/restoreGrub.sh --config-only

# Or on Fedora via the optimization module:
sudo distros/fedora/optimizations/config_grub/setup.sh
```

### Key Configuration Directives in `/etc/default/grub`
```bash
GRUB_TERMINAL_OUTPUT="gfxterm"
GRUB_GFXMODE="auto"
GRUB_GFXPAYLOAD_LINUX="keep"
```
