# USB Wake Disable (Hot Backpack Fix)

Prevents accidental wakeups (such as mouse movement, touchpads, or USB peripherals in a backpack) from waking the laptop and draining battery while in sleep mode.

## How it Works
- Strictly disables USB controllers (`XHCI`/`XHC`) in `/proc/acpi/wakeup` and USB devices in `/sys/bus/usb/devices/*/power/wakeup`.
- **Never touches PCIe root ports, GPU lanes, or power buttons**: Power button (`PWRB`) and lid open switch (`LID`) remain fully functional to wake the machine without black-screen hangs or freezing.
- Runs as a clean oneshot systemd service (`disable-xhci-wake.service`) with zero udev process spawning overhead.
