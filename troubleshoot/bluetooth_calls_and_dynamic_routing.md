# Bluetooth Audio Quality, Dynamic Call Switching, and Hardware Stabilization

## Problem Overview

On modern Linux distributions (Fedora, Arch Linux, Ubuntu, OmArchy) using PipeWire / WirePlumber with Bluetooth headphones and earbuds (e.g., OnePlus Nord Buds 4 Pro, Sony WH/WF series, Galaxy Buds, AirPods, Bose QC):

1. **Stuck in Degraded Telephony Audio (Mono 8kHz CVSD)**:
   - When an application initiates a voice call (Zoom, Microsoft Teams, Discord, Google Meet, WebRTC in browsers), WirePlumber switches the Bluetooth device profile to `headset-head-unit`.
   - Stock WirePlumber 0.5 defaults to `bluetooth.use-persistent-storage = true` and `device.restore-profile = true`, saving `headset-head-unit` into `~/.local/state/wireplumber/default-profile`.
   - Upon reconnecting, turning Bluetooth off/on, or fast toggling rfkill, WirePlumber restores `headset-head-unit` rather than high-fidelity A2DP.
2. **Default Source Inversion & Rogue Stream Capture**:
   - Stock WirePlumber assigns Bluetooth loopback input nodes (`bluez_input.*`) `priority.session = 2010`, higher than internal laptop microphones (`2009`).
   - Background applications bind to `bluez_input`, holding the loopback open and preventing WirePlumber from restoring A2DP stereo (`s-device: Could not find valid non-headset profile, not switching`).
3. **Intel AX211 (`8087:0033`) `force_scofix=1` Misconfiguration & SCO Packet Corruption**:
   - Setting `force_scofix=1` in `/etc/modprobe.d/btusb.conf` enables the kernel `BTUSB_WRONG_SCO_MTU` quirk (intended only for legacy Broadcom/CSR chips), clamping `hdev->sco_mtu = 64`.
   - On Intel AX211 (`BTUSB_INTEL_COMBINED`), forcing `force_scofix=1` overrides the hardware-reported SCO MTU and **still triggers** (or worsens) `Bluetooth: hci0: corrupted SCO packet` and `SCO packet for unknown connection handle 257` during HFP/mSBC calls, crashing `bluez_input`/`bluez_output` PipeWire nodes.
4. **Wi-Fi / Bluetooth Coexistence Stalls (`Missing completion reports for packet`)**:
   - On Intel CNVi combo cards (e.g., Raptor Lake CNVi Wi-Fi `8086:7a70` + AX211 BT `8087:0033`), heavy 2.4 GHz Wi-Fi traffic or coexistence contention (`iwlwifi bt_coex_active=Y`) can stall HCI TX completion reports, causing `spa.bluez5.sink.media: Missing completion reports for packet: Bluetooth adapter firmware bug?` and sudden A2DP dropouts.
5. **RFCOMM / BAP Socket Collisions (`rfcomm_bind: Address already in use (98)`)**:
   - Including `hfp_hf` (Hands-Free Unit role, where the laptop acts as a headset for a phone) in `bluez5.roles` alongside multi-session WirePlumber (`gdm` greeter + user session) or restarting `bluetooth.service` without restarting user `wireplumber` causes `src/profile.c:ext_start_servers() RFCOMM server failed for Hands-Free unit: rfcomm_bind: Address already in use (98)`.
   - Including `bap_sink` / `bap_source` without `KernelExperimental` ISO sockets enabled in BlueZ causes `bap: Operation not supported (95)`.

---

## Architectural Solution

### 1. WirePlumber 0.5 Dynamic Profile Autoswitching (`core/config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf`)

Enables seamless call switching without ever getting stuck:
- **Call -> Headset Profile**: When a call application actively links to the Bluetooth microphone, WirePlumber automatically switches to `headset-head-unit` (16kHz mSBC HD Voice).
- **Else -> High-Quality A2DP Stereo**: When the call ends, WirePlumber automatically restores A2DP stereo within 1500ms (`bluetooth.autoswitch-restore-timeout = 1500`).
- **Never Stuck**: Disables persistent profile saving (`bluetooth.use-persistent-storage = false`, `device.restore-profile = false`).
- **Microphone Priority Ordering**: Sets `~bluez_input.*` to `priority.session = 500` (below internal laptop mic at `2009`), and `~bluez_output.*` to `priority.session = 2050` (above laptop speakers at `1009`).
- **Recommended Role Hygiene**: For laptops/desktops connecting to Bluetooth headphones (not acting as a phone speakerphone), omit `hfp_hf` (to avoid `rfcomm_bind: Address already in use (98)` across GDM/user sessions and seat switches) and omit `bap_sink`/`bap_source` unless kernel ISO sockets are enabled:
  ```hocon
  bluez5.roles = [ "a2dp_sink", "a2dp_source", "hfp_ag" ]
  ```

### 2. Kernel & Hardware Hardening (`hardware-linux/bluetooth/`)

- **Kernel Module Quirks (`/etc/modprobe.d/btusb.conf`)**:
  ```ini
  options btusb enable_autosuspend=0
  ```
  - `enable_autosuspend=0`: Keeps the transceiver powered, preventing USB runtime-PM sleep desync during audio transitions.
  - **Do not** set `force_scofix=1` on Intel AX211 (`8087:0033`), and reload `btusb` (plus regenerate initramfs with `sudo dracut --regenerate-all --force` on Fedora if `/etc/modprobe.d/btusb.conf` was embedded by `dracut`) after changing `btusb.conf`.
- **USB Power Control Udev Rule (`/etc/udev/rules.d/50-btusb-power.rules`)**:
  ```udev
  ACTION=="add|change", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="8087", ATTR{idProduct}=="0033", ATTR{power/control}="on"
  ACTION=="add|change", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{bDeviceClass}=="e0", ATTR{bDeviceSubClass}=="01", ATTR{bDeviceProtocol}=="01", ATTR{power/control}="on"
  ```
  Prevents ACPI/USB runtime-PM from power-gating the Bluetooth controller across `add` and `udevadm trigger` (`change`) events.
- **BlueZ Daemon Optimization (`/etc/bluetooth/main.conf`)**:
  - `FastConnectable = true`: Accelerates page scanning for fast reconnection.
  - `JustWorksRepairing = always`: Prevents pairing key mismatch across dual-boot/reconnects.
  - `Experimental = true`: Enables battery reporting and D-Bus experimental interfaces.
  - `MultiProfile = multiple`: Allows A2DP and HFP endpoints to co-exist cleanly.
  - `AutoEnable = true`: Powers on adapter automatically on boot or resume.
  - `ResumeDelay = 3`: Waits 3 seconds after wake before BlueZ auto-reconnects audio devices so CNVi Wi-Fi/BT and WirePlumber finish resuming.

---

## Optional Workarounds for Stubborn Hardware/Headset Quirks

- **If `spa.bluez5.sink.media: Missing completion reports for packet` persists on 2.4 GHz Wi-Fi**:
  Prefer 5 GHz / 6 GHz Wi-Fi. If 2.4 GHz coexistence still drops A2DP frames, test disabling Intel Wi-Fi/BT coexistence in `/etc/modprobe.d/iwlwifi.conf`:
  ```ini
  options iwlwifi bt_coex_active=0
  ```
  *(Trade-off: may reduce 2.4 GHz Wi-Fi throughput while Bluetooth is active.)*
- **If a specific headset still triggers `corrupted SCO packet` during mSBC calls after removing `force_scofix=1`**:
  Disable wideband mSBC in WirePlumber (`bluez5.enable-msbc = false`) or test `options bluetooth disable_esco=1` in `/etc/modprobe.d/bluetooth.conf` to fall back to standard CVSD/SCO.

---

## Verification & Recovery Commands

1. **Verify Hardware Module, Power Control, and Service State**:
   ```bash
   ~/archConfig/hardware-linux/bluetooth/setup.sh --verify
   cat /sys/module/btusb/parameters/enable_autosuspend   # Expect: N
   cat /sys/module/btusb/parameters/force_scofix         # Expect: N (NOT Y on AX211)
   ```

2. **Verify WirePlumber Status & Codec**:
   ```bash
   systemctl --user status wireplumber --no-pager
   wpctl status
   wpctl inspect @DEFAULT_AUDIO_SINK@
   ```
   Confirm `api.bluez5.profile = "a2dp-sink"` and codec is `aac` / `ldac` / `sbc_xq`.

3. **Verify Call Autoswitching**:
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

4. **Check Logs for Regressions**:
   ```bash
   journalctl -b -k | grep -iE 'btusb|hci0|corrupted SCO|unknown connection handle'
   journalctl -b -u bluetooth --no-pager | tail -n 50
   ```
