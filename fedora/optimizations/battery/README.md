# Battery Charging Limit (85% Cap)

Protects battery longevity by capping charge at 85% on laptops supporting ACPI/sysfs charge thresholds (including ASUS ROG/TUF systems managed via `asusctl`/`asusd` and standard Linux power supplies).

## Features
- **Health Cap (85%)**: Prevents battery wear and swelling caused by continuous 100% state-of-charge.
- **ASUS ROG / TUF Integration**: Seamlessly communicates with `asusd` using `asusctl battery limit 85`, ensuring persistence directly in `/etc/asusd/asusd.ron`.
- **Persistent Across Resume**: Systemd sleep hook (`/usr/lib/systemd/system-sleep/set-battery-limit.sh`) re-applies the limit when resuming from sleep/hibernate (preventing the Embedded Controller from resetting it to 100%).
- **Persistent Across AC Connection**: Udev rule (`/etc/udev/rules.d/90-battery-limit.rules`) re-asserts the limit whenever power supply state changes or the AC adapter is plugged in.
- **Service Integration**: Systemd oneshot unit with `RemainAfterExit=yes` keeps the unit in `active (exited)` state and starts cleanly after `asusd.service`.

## Usage
Run the installer:
```bash
sudo ./install.sh
```
Or apply the limit directly for the current session (works without sudo on ASUS ROG/TUF systems):
```bash
./set-battery-limit.sh
```
Set a custom limit manually:
```bash
BATTERY_LIMIT=80 ./set-battery-limit.sh
```

## Verification
Verify the status of the battery limit:
```bash
./verify.sh
```
