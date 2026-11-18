# Bluetooth Audio & Intel AX211 Hardware Optimization

Ensures Bluetooth headsets (such as OnePlus Nord Buds, AirPods, Galaxy Buds, Sony WH/WF) connect with high-fidelity A2DP AAC/LDAC/SBC-XQ stereo audio, dynamically switches to headset mode during active voice calls, and reliably returns to high-fidelity stereo when calls end or when Bluetooth is toggled.

## Problems Solved
1. **Dynamic Call Switching Without Getting Stuck**:
   - Upstream WirePlumber persisted temporary headset profile (`headset-head-unit`) into local state (`~/.local/state/wireplumber/default-profile`), locking reconnecting or toggled earbuds into low-quality mono audio.
   - Fixed by disabling persistent profile storage (`bluetooth.use-persistent-storage = false`, `device.restore-profile = false`) in `core/config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf`.
   - Reconnected or fast-toggled devices always evaluate and activate high-fidelity A2DP stereo.
2. **Seamless Call Mic Integration (User Requirement)**:
   - When on a call (active capture stream linked to Bluetooth microphone), WirePlumber dynamically switches to HFP headset mode (`headset-head-unit` with 16kHz mSBC HD Voice).
   - When the call ends, WirePlumber automatically restores pristine A2DP high-fidelity stereo within 1500ms.
3. **Microphone Priority Ordering & Rogue Stream Prevention**:
   - Internal laptop microphone maintains `priority.session = 2009`.
   - Bluetooth microphone (`bluez_input.*`) is configured with `priority.session = 500`.
   - Background applications (browsers, volume meters) bind to the internal microphone rather than keeping the Bluetooth headset locked into mono headset mode. Call applications (Discord, Zoom, Meet) can explicitly select the Bluetooth mic at will.
4. **Intel AX211 Controller SCO Corruption & Autosuspend**:
   - Intel AX211 controllers suffer from buffer misalignment and USB sleep during SCO calls (`corrupted SCO packet`).
   - Fixed via `/etc/modprobe.d/btusb.conf` (`options btusb enable_autosuspend=0 force_scofix=1 reset=1`) and `/etc/udev/rules.d/50-btusb-power.rules`.
5. **Post-Sleep BlueZ Deadlocks & Fast Reconnection**:
   - `FastConnectable = true` and `MultiProfile = multiple` in `/etc/bluetooth/main.conf` accelerate page scanning and allow clean A2DP/HFP profile co-existence.
   - Pre-suspend hook disconnects audio streams before USB power cut; post-resume hook re-enables Bluetooth radio to guarantee clean AVDTP re-enumeration.

## Verification
```bash
bash hardware-linux/setup.sh --verify
wpctl status
wpctl inspect @DEFAULT_AUDIO_SINK@
```
