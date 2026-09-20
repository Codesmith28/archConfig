# GRUB Configuration (Fedora & Linux)

Configures the GRUB bootloader graphical terminal, display resolution, and transition settings on Fedora (and other Linux distributions).

## Features
- **Graphical Terminal Mode (`gfxterm`)**: Replaces Fedora's default `GRUB_TERMINAL_OUTPUT="console"` text mode with `gfxterm`, allowing graphical rendering and high resolutions.
- **Font Provisioning**: Automatically installs the Unicode font into `/boot/grub2/fonts/unicode.pf2` so GRUB can render text in graphics mode before the root filesystem is mounted.
- **Native Resolution Detection**: Auto-detects native screen resolution from DRM modes (e.g. `1920x1200,auto`).
- **Seamless Hand-off (`GRUB_GFXPAYLOAD_LINUX=keep`)**: Avoids screen flashing or mode re-initialization during kernel hand-off to Plymouth splash.
- **Safety**: Automatically creates a timestamped backup before modifying `/etc/default/grub` and rolls back if `grub2-mkconfig` fails.
- **Multi-distro Compatibility**: Supports `grub2-mkconfig` (Fedora/RHEL), `update-grub` (Debian/Ubuntu), and `grub-mkconfig` (Arch).

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
