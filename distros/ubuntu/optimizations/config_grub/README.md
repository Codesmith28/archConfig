# GRUB Configuration (Ubuntu)

Configures the GRUB bootloader display resolution and transition settings on Ubuntu.

## Features
- Sets high-resolution display mode (defaults to `1920x1200,auto`).
- Configures `GRUB_GFXPAYLOAD_LINUX=keep` to avoid screen flashing / resync during the handoff to the Linux kernel splash.
- Automatically creates a timestamped backup before applying modifications.
- Performs automatic rollback if `update-grub` fails.

## Usage

Run the setup script:
```bash
./setup.sh
```
Or specify a custom resolution if needed:
```bash
./setup.sh "1920x1200,auto"
```
*(If run as a regular user, it will invoke `sudo` automatically).*
