# GRUB Graphical Terminal (High-Resolution) Setup (Fedora)

Configures the GRUB bootloader to use `gfxterm` graphical mode, which automatically selects the best native display resolution on UEFI systems.

## Why GRUB Defaults to Low Resolution on Fedora
Fedora ships with `GRUB_TERMINAL_OUTPUT="console"` by default in `/etc/default/grub`. This explicitly locks GRUB into low-resolution 80x25 text console mode, bypassing UEFI GOP (Graphics Output Protocol).

## The Fix: `GRUB_TERMINAL_OUTPUT="gfxterm"`
Setting `GRUB_TERMINAL_OUTPUT="gfxterm"` enables the graphical terminal, which natively queries UEFI GOP to automatically choose the best available resolution for any screen (e.g. `1920x1080`, `1920x1200`, `2K`, `4K`) without needing manual resolution probing or hardcoded mode strings.

## Features
- **Automatic Native Resolution**: Uses `GRUB_TERMINAL_OUTPUT="gfxterm"` so UEFI GOP automatically picks the best display mode.
- **Font Provisioning (`/boot/grub2/fonts/unicode.pf2`)**: Provisions the font in `/boot` required by `gfxterm`.
- **Cleanup of Prior Attempts**: Strips out manual `GRUB_GFXMODE` lines, duplicate entries, and old backup files.

## Usage
Run with sudo:
```bash
sudo ./setup.sh
```
Or from the parent optimizations directory:
```bash
sudo ./setup.sh config_grub
```

## Verification
Check current GRUB configuration status:
```bash
./setup.sh --verify
```
