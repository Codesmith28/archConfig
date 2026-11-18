# GRUB Configuration (Ubuntu)

Configures the GRUB bootloader to use `gfxterm` graphical mode with native display resolution via UEFI GOP without hardcoding resolution numbers or injecting conflicting font overrides.

## Features
- **UEFI GOP Auto-Resolution (`GRUB_GFXMODE="auto"`)**: Uses UEFI GOP automatic mode negotiation to render at the display's native resolution without hardcoded numbers.
- **Graphical Terminal (`gfxterm`)**: Replaces plain console mode to enable high-resolution UEFI GOP rendering.
- **Smooth Kernel Handoff**: Configures `GRUB_GFXPAYLOAD_LINUX="keep"` to avoid screen flashing or resolution reset during the handoff to Plymouth and the Linux kernel splash.
- **Config Sanitation**: Automatically purges prior multiline corruption, ANSI escape sequences, and clashing `GRUB_FONT` overrides from `/etc/default/grub`.
- **Safety Rollback**: Automatically creates a timestamped backup before applying modifications and performs automatic rollback if `update-grub` fails.

## Usage

Check current GRUB configuration status (non-destructive):
```bash
./setup.sh --verify
```

Apply clean configuration and regenerate bootloader:
```bash
sudo ./setup.sh
```
