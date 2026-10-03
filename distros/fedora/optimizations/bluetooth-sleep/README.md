# Bluetooth Sleep & Audio Resynchronization Hook

Ensures Bluetooth headsets (such as OnePlus Nord Buds) disconnect cleanly before system sleep and re-synchronize with high-fidelity A2DP AAC stereo on resume.

## Problem Solved
- When modern laptops suspend, the USB root hub resets or cuts power abruptly (`xhci_hcd` reset).
- Bluetooth headsets remain in a half-open AVDTP streaming session because they received no disconnect handshake.
- Upon resume, BlueZ reports `Unable to select SEP` or `a2dp-source profile connect failed: Device or resource busy`.
- Audio drops to low-bandwidth telephone quality (HFP/HSP 8kHz mono), or WirePlumber deadlocks if services are restarted.

## How it Works
- Installs `/usr/lib/systemd/system-sleep/bluetooth-sleep.sh`.
- **Pre-suspend (`pre`)**: Gracefully disconnects active Bluetooth devices before the radio powers down, allowing headset firmware to cleanly close AVDTP.
- **Post-resume (`post`)**: Waits 2 seconds for the USB controller to re-enumerate and powers on Bluetooth, ensuring devices reconnect with high-fidelity A2DP stereo.
