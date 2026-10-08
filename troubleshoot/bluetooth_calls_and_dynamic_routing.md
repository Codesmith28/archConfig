# Bluetooth Calls, Dynamic Profile Switching, and Intel SCO Hardware Fix

## Problem Overview

On modern Linux desktops with PipeWire/WirePlumber and Bluetooth headsets (e.g. OnePlus Nord Buds 4 Pro, Sony WH/WF, Galaxy Buds) connected to Intel wireless adapters (e.g., Intel Wi-Fi 6E AX211):

1. **Stuck in Degraded Telephony / Mono Audio (CVSD/HFP)**:
   - WirePlumber's persistent storage saved `headset-head-unit` to `~/.local/state/wireplumber/default-profile`.
   - On connect or login, the earbuds loaded in mono headset mode globally even when no call or microphone application was active.
   - Disabling mSBC wideband speech downgraded call quality to 8 kHz CVSD (narrowband landline telephone quality).
2. **Failure to Restore High-Fidelity AAC Stereo After Calls**:
   - Upstream WirePlumber 0.5's `autoswitch-bluetooth-profile.lua` script failed to discover A2DP routes inside `EnumRoute` while in headset mode (`s-device: Could not find valid non-headset profile, not switching`), preventing automatic restoration to AAC.
   - WirePlumber 0.5 loads scripts from `XDG_DATA_HOME` (`~/.local/share/wireplumber/scripts/`) rather than `~/.config/wireplumber/scripts/`.
3. **Bluetooth SCO Packet Corruption on Intel AX211**:
   - The Linux `btusb` module enters USB autosuspend and misaligns synchronous connection-oriented (SCO) audio packets during calls.
   - This caused `Bluetooth: hci0: corrupted SCO packet`, socket reset, and broken Bluetooth audio transports when switching or ending calls.

---

## Root Causes & Solutions

### 1. WirePlumber Configuration (`core/config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf`)

- **Disable Persistent Headset Mode**:
  `bluetooth.use-persistent-storage = false` prevents WirePlumber from persisting headset mode across sessions or reconnects. The earbuds always initialize in **High-Fidelity AAC Stereo**.
- **Enable mSBC HD Voice**:
  `bluez5.enable-msbc = true` ensures that when headset mode is active during a call, speech uses 16 kHz wideband audio (mSBC HD Voice) rather than tinny 8 kHz CVSD.
- **Dynamic Stream Routing & Priority**:
  - `node.stream.restore-target = false` and `node.restore-default-targets = false` allow streams to follow Bluetooth dynamically as soon as connected.
  - Sinks and sources set to priority `2050` cleanly outrank built-in ALSA hardware (`1009` output, `2009` input) without stream locking.

### 2. Custom WirePlumber Autoswitch Script (`core/config/wireplumber/scripts/device/autoswitch-bluetooth-profile.lua`)

Symlinked to `~/.local/share/wireplumber/scripts/device/autoswitch-bluetooth-profile.lua`:
- **Direct EnumProfile Resolution**:
  Instead of failing when `EnumRoute` hides A2DP routes during calls, `highestPrioNonHeadsetProfile` directly resolves the highest priority `^a2dp` profile (`a2dp-sink` AAC, priority 133).
- **Accurate Headset Detection**:
  Fixed `isHeadsetProfile` so `headset-head-unit` is correctly identified without relying on dynamic route availability.
- **Real-Time Profile Switching & Restoration (0 ms)**:
  `PROFILE_RESTORE_TIMEOUT_MSEC = 0` and `PROFILE_SWITCH_TIMEOUT_MSEC = 0` eliminate all non-real-time debounce delays. Profile transitions happen in real time on the immediate next event loop tick the instant a call or microphone stream begins or ends.

### 3. Kernel Bluetooth Module Quirks (`troubleshoot/fix_intel_bluetooth_sco.sh`)

Writes `/etc/modprobe.d/btusb.conf`:
```ini
options btusb enable_autosuspend=0 force_scofix=1 reset=1
```
- `enable_autosuspend=0`: Prevents the Intel AX211 controller from sleeping and dropping audio packets.
- `force_scofix=1`: Forces correct SCO buffer alignment in the Linux kernel for Intel hardware.
- `reset=1`: Resets the controller on initialization to prevent hung HCI handles.

---

## Verification & Status

Check current status:
```bash
wpctl status
```
Verify device profile:
```bash
pw-cli e <device-id> Profile
```
Ensure profile reports `High Fidelity Playback (A2DP Sink, codec AAC)` outside of calls, and `Headset Head Unit (HSP/HFP, codec MSBC)` during calls.
