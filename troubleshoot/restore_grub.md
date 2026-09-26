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

If Linux boots fine but the Windows option is missing:

1. Install `os-prober`:
   * **Arch**: `sudo pacman -S os-prober`
   * **Fedora**: `sudo dnf install os-prober`
   * **Ubuntu**: `sudo apt install os-prober`

2. Enable `os-prober` in `/etc/default/grub`:
   ```bash
   echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub
   ```

3. Regenerate the GRUB config:
   * **Arch / Ubuntu**:
     ```bash
     sudo grub-mkconfig -o /boot/grub/grub.cfg
     ```
   * **Fedora (UEFI)**:
     ```bash
     sudo grub2-mkconfig -o /etc/grub2-efi.cfg
     ```
