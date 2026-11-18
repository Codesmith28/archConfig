# Bluetooth Audio Quality, Dynamic Call Switching, and Hardware Stabilization

## Problem Overview

On modern Linux distributions (Fedora, Arch Linux, Ubuntu) using PipeWire / WirePlumber with Bluetooth headphones and earbuds (e.g., OnePlus Nord Buds 4 Pro, Sony WH/WF series, Galaxy Buds, AirPods, Bose QC):

1. **Stuck in Degraded Telephony Audio (Mono 8kHz CVSD)**:
   - When an application initiated a voice call (Zoom, Microsoft Teams, Discord, Google Meet, WebRTC in browsers), WirePlumber switched the Bluetooth device profile to `headset-head-unit`.
   - WirePlumber 0.5 defaulted to `bluetooth.use-persistent-storage = true` and `device.restore-profile = true`. It saved `headset-head-unit` into `~/.local/state/wireplumber/default-profile`.
   - Upon reconnecting, turning Bluetooth off/on, or fast toggling rfkill, WirePlumber restored `headset-head-unit` rather than evaluating high-fidelity A2DP, permanently trapping the user in muffled, low-bitrate mono audio.
2. **Default Source Inversion & Rogue Stream Capture**:
   - Stock WirePlumber assigns Bluetooth loopback input nodes (`bluez_input.*`) `priority.session = 2010`.
   - Because internal laptop microphones have `priority.session = 2009`, `bluez_input` becomes the system default recording device.
   - Any background application (browser tab checking media permissions, game launcher, volume meters) immediately bound to `bluez_input`, holding the Bluetooth loopback stream open and preventing WirePlumber from ever restoring A2DP stereo.
3. **Intel AX211 Controller SCO Packet Corruption (`btusb`)**:
   - Intel CNVi Bluetooth controllers (such as AX201, AX210, AX211 `8087:0033`) suffer from SCO buffer sizing mismatches and USB runtime-PM race conditions when `force_scofix=N` and `enable_autosuspend=Y`.
   - Engaging HFP/SCO caused kernel errors: `Bluetooth: hci0: corrupted SCO packet` and `SCO packet for unknown connection handle 257`.
   - This corrupted the HCI transport, throwing `spa.bluez5: Failure in Bluetooth audio transport` and BlueZ `SET_CONFIGURATION request rejected: Stream End Point in Use (19)`, removing A2DP endpoints from BlueZ's cache and causing WirePlumber to log:
     `s-device: Could not find valid non-headset profile, not switching`.

---

## Architectural Solution

### 1. WirePlumber 0.5 Dynamic Profile Autoswitching (`core/config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf`)

Enables seamless call switching without ever getting stuck:
- **Call -> Headset Profile**: When a call application actively links to the Bluetooth microphone, WirePlumber automatically switches to `headset-head-unit` (upgraded to 16kHz mSBC HD Voice).
- **Else -> High-Quality A2DP Stereo**: When the call ends, WirePlumber automatically restores pristine A2DP stereo within 1500ms (`bluetooth.autoswitch-restore-timeout = 1500`).
- **Never Stuck**: Disables persistent profile saving (`bluetooth.use-persistent-storage = false`, `device.restore-profile = false`). When connecting or power toggling, WirePlumber always evaluates and selects the highest-priority A2DP profile.
- **Microphone Priority Ordering**: Sets `~bluez_input.*` to `priority.session = 500` (below internal laptop mic at `2009`). The laptop microphone remains the default capture device for general system usage, while the Bluetooth mic remains fully available for explicit selection in call software.
- **Playback Priority**: Sets `~bluez_output.*` to `priority.session = 2050` (above laptop speakers at `1009`) so connected Bluetooth headphones instantly become the active default sink.

```hocon
wireplumber.settings = {
  bluetooth.autoswitch-to-headset-profile = true
  bluetooth.autoswitch-switch-timeout = 500
  bluetooth.autoswitch-restore-timeout = 1500

  bluetooth.use-persistent-storage = false
  device.restore-profile = false

  bluetooth.profile-preference = "quality"
  node.stream.restore-target = false
  node.restore-default-targets = false
  linking.follow-default-target = true
  linking.allow-moving-streams = true
}

monitor.bluez.properties = {
  bluez5.codecs = [ "ldac", "aptx_hd", "aptx", "aac", "sbc_xq", "sbc" ]
  bluez5.enable-sbc-xq = true
  bluez5.enable-msbc = true
  bluez5.enable-hw-volume = true
  bluez5.roles = [ "a2dp_sink", "a2dp_source", "hfp_hf", "hfp_ag", "bap_sink", "bap_source" ]
  bluez5.hfphsp-backend = "native"
}

monitor.bluez.rules = [
  {
    matches = [ { node.name = "~bluez_output.*" } ]
    actions = { update-props = { priority.session = 2050, priority.driver = 2050 } }
  }
  {
    matches = [ { node.name = "~bluez_input.*" } ]
    actions = { update-props = { priority.session = 500, priority.driver = 500 } }
  }
]
```

### 2. Kernel & Hardware Hardening (`hardware-linux/bluetooth/`)

- **Kernel Module Quirks (`/etc/modprobe.d/btusb.conf`)**:
  ```ini
  options btusb enable_autosuspend=0 force_scofix=1 reset=1
  ```
  - `force_scofix=1`: Enforces SCO buffer alignment in the Linux kernel for Intel hardware, preventing HCI transport crashes.
  - `enable_autosuspend=0`: Keeps the transceiver powered, preventing sleep desync during audio transitions.
  - `reset=1`: Resets the HCI controller on module reload to clear dirty states.
- **USB Power Control Udev Rule (`/etc/udev/rules.d/50-btusb-power.rules`)**:
  ```udev
  ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0033", ATTR{power/control}="on"
  ```
  Prevents ACPI/USB core from power-gating the Intel AX211 transceiver.
- **BlueZ Daemon Optimization (`/etc/bluetooth/main.conf`)**:
  - `FastConnectable = true`: Accelerates page scanning for instant reconnection upon fast toggling.
  - `MultiProfile = multiple`: Allows A2DP and HFP endpoints to co-exist cleanly.
  - `AutoEnable = true`: Powers on adapter automatically on boot or resume.

---

## Verification & Recovery Commands

1. **Verify WirePlumber Status & Codec**:
   ```bash
   systemctl --user status wireplumber --no-pager
   wpctl status
   wpctl inspect @DEFAULT_AUDIO_SINK@
   ```
   Confirm `api.bluez5.profile = "a2dp-sink"` and codec is `aac` / `ldac` / `sbc_xq`.

2. **Verify Call Autoswitching**:
   ```bash
   # Start recording from Bluetooth mic:
   parec -d <bluez_input_name> > /dev/null &
   PID=$!
   sleep 2
   # Inspect active profile (switches to headset-head-unit):
   pactl list cards | grep "Active Profile"
   # Stop call recording:
   kill $PID
   sleep 2
   # Inspect active profile (automatically restored to a2dp-sink):
   pactl list cards | grep "Active Profile"
   ```

3. **Verify Fast Toggling Bluetooth**:
   ```bash
   bluetoothctl power off && sleep 1 && bluetoothctl power on
   # Reconnect and inspect:
   wpctl status
   ```
   Headset reconnects cleanly in `a2dp-sink` without driver hangs.
