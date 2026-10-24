# GRUB Graphical Terminal (High-Resolution) Setup (Fedora)

Configures the GRUB bootloader to use `gfxterm` graphical mode, which automatically selects the best native display resolution on UEFI systems.

## Why GRUB Defaults to Low Resolution on Fedora
Fedora ships with `GRUB_TERMINAL_OUTPUT="console"` by default in `/etc/default/grub`. This explicitly locks GRUB into low-resolution 80x25 text console mode, bypassing UEFI GOP (Graphics Output Protocol).

## The Fix: `gfxterm` + Native Panel Resolution
1. **`GRUB_TERMINAL_OUTPUT="gfxterm"`**: Switches from legacy text console mode to the high-resolution graphical framebuffer.
2. **`GRUB_GFXMODE="<native>x32,<native>,auto"`**: Dynamically detects the display's native resolution (e.g. `1920x1200` for 16:10 ROG panels) with 32-bit color depth, rather than letting UEFI GOP fall back to default `1024x768`.
3. **`GRUB_GFXPAYLOAD_LINUX="keep"`**: Keeps the high-resolution graphical framebuffer active during the kernel handover, preventing display mode resets and flicker.
4. **Font Provisioning**: Provisions `/boot/grub2/fonts/unicode.pf2` so text renders crisp and sharp at native DPI.

## Features
- **Dynamic Native Resolution Detection**: Automatically discovers display panel resolution from `/sys/class/drm/*/modes` (e.g., `1920x1200`).
- **Smooth Graphical Handover**: `GRUB_GFXPAYLOAD_LINUX="keep"` ensures zero flicker from bootloader to Plymouth and Wayland.
- **Font Provisioning (`/boot/grub2/fonts/unicode.pf2`)**: Provisions the font in `/boot` required by `gfxterm`.

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
