# Battery Charging Limit & Deep Sleep Management

Protects battery longevity and prevents suspend battery drain by capping charge at 85% and configuring deep sleep (S3 Suspend-to-RAM) on Fedora / Linux.

## Features
- **Health Cap (85%)**: Prevents battery wear and degradation caused by continuous 100% state-of-charge.
- **Deep Sleep (S3 Suspend-to-RAM)**: Switches kernel sleep mode from battery-draining `s2idle` (modern standby) to `deep` sleep, eliminating high backpack/overnight battery drain during suspend.
- **Deep Sleep Persistence**:
  - `systemd-tmpfiles` (`/etc/tmpfiles.d/deep-sleep.conf`): writes `deep` to `/sys/power/mem_sleep` on early boot.
  - `systemd` sleep configuration (`/etc/systemd/sleep.conf.d/deep-sleep.conf`): sets `MemorySleepMode=deep`.
  - Kernel boot parameters via `grubby` & `/etc/default/grub`: sets `mem_sleep_default=deep` across all kernels.
- **ASUS ROG / TUF Integration**: Seamlessly communicates with `asusd` using `asusctl battery limit 85`, ensuring persistence directly in `/etc/asusd/asusd.ron`.
- **Persistent Across Resume**: Systemd sleep hook (`/usr/lib/systemd/system-sleep/set-battery-limit.sh`) re-applies the limit and deep sleep mode when resuming from sleep/hibernate.
- **Persistent Across AC Connection**: Udev rule (`/etc/udev/rules.d/90-battery-limit.rules`) re-asserts the limit whenever power supply state changes or the AC adapter is plugged in.
- **Service Integration**: Systemd oneshot unit `battery-limit.service` starts cleanly on boot after `asusd.service`.

## Usage
Run setup with root privileges (configures services, udev rules, and boot persistence):
```bash
sudo ./setup.sh
```
Or apply for the current session:
```bash
./setup.sh
```
Set a custom limit manually:
```bash
BATTERY_LIMIT=80 sudo ./setup.sh
```

## Verification
Verify current charging threshold and sleep mode status:
```bash
./setup.sh --verify
```
