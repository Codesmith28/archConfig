# USB Wake Isolation (Hot Backpack Fix + Keyboard Wake)

Properly isolates USB and ACPI wake triggers on Fedora and Linux: enables keyboard wake while preventing accidental backpack wakeups caused by mice, network, and other peripherals.

## The Problem
Many laptops suffer from "hot backpack syndrome":
- Disabling the USB controller (`XHCI`) in `/proc/acpi/wakeup` prevents accidental wakeups, but breaks all keyboard wakeups because modern laptop keyboards (such as ASUS ROG/TUF N-KEY keyboards) and external USB keyboards connect internally via the XHCI controller. None of the keyboard keys can wake the suspended laptop.
- Leaving all USB wakeup triggers enabled allows optical mice, wireless mouse dongles, touchpads, and Bluetooth devices to wake the system when jostled in a bag.

## The Solution
`isolate-wake` isolates wake triggers at both the ACPI and USB sysfs layers:
1. **ACPI Layer (`/proc/acpi/wakeup`)**:
   - Keeps `XHCI` (USB controller), `PWRB` (Power button), `SLPB` (Sleep button), and `LID` (Lid switch) enabled.
   - Disables `CNVW` (Wake-on-WLAN/Bluetooth), `XDCI`, `HDAS` (Audio), and PCIe root port wake triggers.
2. **USB Subsystem Layer (`sysfs`)**:
   - Enables wakeup on XHCI host controllers and USB root hubs (`usb1`, `usb2`, etc.).
   - Enables wakeup on USB hubs and docks so downstream keyboards can wake through them.
   - Scans connected USB devices:
     - **Keyboards** (`bInterfaceClass=03`, `bInterfaceProtocol=01`, ASUS N-KEY devices): `power/wakeup` set to `enabled`. Pressing any key will wake the laptop.
     - **Mice / Pointing Devices** (`bInterfaceProtocol=02`, mice, trackballs): `power/wakeup` set to `disabled`. Motion and clicks will not wake the laptop.
     - **Peripherals** (webcams, Bluetooth controllers): `power/wakeup` set to `disabled`.
3. **Dynamic & Pre-Suspend Hooks**:
   - **Systemd Service**: Runs at boot (`disable-xhci-wake.service`).
   - **Udev Rule**: Automatically applies wake rules when USB devices are plugged or unplugged (`/etc/udev/rules.d/90-usb-wake-isolate.rules`).
   - **Systemd Sleep Hook**: Enforces policies immediately before suspend (`/usr/lib/systemd/system-sleep/isolate-wake.sh`).

## Installation

Run the installer with sudo:
```bash
sudo ./setup.sh
```
Or run via the main optimizations setup:
```bash
sudo ../setup.sh usb-wake
```

## Verification

Check that XHCI is enabled in ACPI:
```bash
cat /proc/acpi/wakeup | grep XHCI
# Should show: XHCI   S3   *enabled
```

Check that USB host controller and root hubs have wakeup enabled:
```bash
cat /sys/bus/pci/drivers/xhci_hcd/*/power/wakeup
cat /sys/bus/usb/devices/usb*/power/wakeup
# Should show: enabled
```

Check keyboard vs peripheral wakeup:
```bash
for dev in /sys/bus/usb/devices/*; do
  [ -f "$dev/power/wakeup" ] && [[ ! "$dev" =~ /usb[0-9]+$ ]] && \
  echo "$(basename "$dev") ($(cat "$dev/product" 2>/dev/null || echo 'unnamed')): $(cat "$dev/power/wakeup")"
done
```
