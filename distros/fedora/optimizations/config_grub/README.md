# GRUB Graphical Terminal & High-Resolution Setup (Fedora)

Configures the GRUB bootloader to use `gfxterm` graphical mode with native display resolution via UEFI GOP without hardcoding resolution numbers or injecting conflicting font overrides.

## Why GRUB Defaults to Low Resolution on Fedora

1. **Text Console Default**: Fedora ships with `GRUB_TERMINAL_OUTPUT="console"` by default in `/etc/default/grub`. This explicitly locks GRUB into low-resolution 80x25 text console mode, bypassing UEFI GOP (Graphics Output Protocol).
2. **Corrupted or Misconfigured `GRUB_FONT`**: In `/etc/grub.d/00_header`, if `GRUB_FONT` contains missing paths or multiline script/ANSI pollution, GRUB aborts graphical initialization and drops back to legacy 80x25 text console. In UEFI GOP mode, omitting `GRUB_FONT` allows GRUB to cleanly use firmware GOP rendering without font loader gating failures.
3. **Hardcoding Fragility**: Hardcoding resolution numbers (e.g. `1920x1200` or `2560x1600`) breaks when external monitors, docking stations, or differing panels are connected. Setting `GRUB_GFXMODE="auto"` instructs UEFI GOP to query the EDID and select the native panel resolution cleanly without manual overrides.
4. **Kernel Mode Switch**: Without `GRUB_GFXPAYLOAD_LINUX="keep"`, the framebuffer can reset or flash back to text mode during early kernel boot.

## The Fix

1. **`GRUB_TERMINAL_OUTPUT="gfxterm"`**: Enables the graphical terminal to hook into the UEFI Graphics Output Protocol.
2. **UEFI GOP Auto-Resolution (`GRUB_GFXMODE="auto"`)**: Allows UEFI GOP firmware to automatically initialize the display at its native high resolution (e.g. 1920x1200 / 2560x1600 / 4K) without fragile hardcoded numbers.
3. **Seamless Kernel Handoff (`GRUB_GFXPAYLOAD_LINUX="keep"`)**: Configures `GRUB_GFXPAYLOAD_LINUX="keep"` to prevent screen flicker or resolution reset during handoff from GRUB to Plymouth/Linux kernel.
4. **Config Sanitation**: Automatically purges prior multiline corruption, ANSI escape sequences, and clashing `GRUB_FONT` overrides from `/etc/default/grub`.

## Usage

Check current GRUB configuration status (non-destructive):
```bash
./setup.sh --verify
```

Apply clean configuration and regenerate bootloader (requires sudo):
```bash
sudo ./setup.sh
# or from parent optimizations directory:
sudo ./setup.sh config_grub
```

---

See also: **[GRUB High-Resolution Troubleshooting Runbook](file:///home/codesmith28/archConfig/troubleshoot/grub-resolution.md)** for detailed root cause analysis and multi-distro recovery guides.
