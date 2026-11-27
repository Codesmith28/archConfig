# Troubleshooting: Bluetooth Audio Failure & GNOME Shortcuts Lockup After Sleep

## Symptoms
After waking the system from sleep/suspend:
1. **Bluetooth connects without audio or fails to reconnect**: The headset (e.g. OnePlus Nord Buds 4 Pro) stays disconnected or connects without A2DP (`Unable to load LastUsed: rseid 1 not found`, `Unable to select SEP`, `a2dp-source profile connect failed: Device or resource busy`).
2. **Profile/RFCOMM errors on resume or daemon restart**: `bluetoothd` logs `RFCOMM server failed for Hands-Free unit: rfcomm_bind: Address already in use (98)` and WirePlumber logs `spa.bluez5.midi: RegisterApplication() failed: Already Exists`.
3. **Volume buttons (Vol +/-) stop working**: Pressing hardware volume keys produces no volume changes and no OSD feedback.
4. **`Super + Return` (Ghostty terminal) does not work**: Custom shortcuts are ignored.

---

## 🔍 Root Cause Analysis: The Cascade of Failure

The problem is a **cascading domino failure** across the kernel, BlueZ, PipeWire/WirePlumber, and GNOME settings daemon:

1. **Abrupt suspend & half-open AVDTP state**:
   - If the Bluetooth headset is not cleanly disconnected before the xHCI/CNVi controller enters S3 deep sleep, the headset holds a stale AVDTP stream endpoint. On resume, BlueZ hits `Unable to load LastUsed: rseid 1 not found` / `Unable to select SEP` / `SET_CONFIGURATION request rejected: Stream End Point in Use (19)`.
   - Previously, `hardware-linux/bluetooth/bluetooth-sleep.sh` disconnected devices on `pre` without waiting for L2CAP/AVDTP teardown, never recorded which devices were connected, and only ran `bluetoothctl power on` on `post` (never reconnecting them or waiting for `hci0` readiness).
2. **`bluetooth.service` restarted in isolation (without restarting user `wireplumber`)**:
   - Running `sudo ./hardware-linux/bluetooth/setup.sh` restarted `bluetooth.service`, then skipped restarting `wireplumber` because `id -u == 0`.
   - Leaving `wireplumber` running across a `bluetoothd` restart (or running `hfp_hf` across both GDM and user sessions during seat transitions) leaves stale RFCOMM/BlueZ sockets bound, triggering `rfcomm_bind: Address already in use (98)` and WirePlumber IPC deadlocks.
3. **GNOME `gsd-media-keys` deadlock on stalled PipeWire**:
   - When `org.gnome.desktop.sound input-feedback-sounds` is `true`, `gsd-media-keys` calls `libcanberra-pulse` (`pa_threaded_mainloop_wait()`) synchronously on volume key presses. If PipeWire/WirePlumber is hung, `gsd-media-keys` freezes and stops dispatching all custom shortcuts (`Super + Return`, media keys).

---

## 🔬 Evidence & Diagnostic Traces

### 1. `gsd-media-keys` Deadlock Trace
Attaching `gdb` to `gsd-media-keys` during the frozen state revealed the blocking call in Thread 1:
```text
#0  0x00007f8cad5f3352 in __syscall_cancel_arch () from /lib64/libc.so.6
#1  0x00007f8cad5ea0ec in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libc.so.6
#2  0x00007f8cada3e7af in pa_threaded_mainloop_wait () from /lib64/libpulse.so.0
#3  0x00007f8cac3b0848 in pulse_driver_open () from /usr/lib64/libcanberra-0.30/libcanberra-pulse.so
#4  0x00007f8cade367b6 in ca_context_play_full () from /lib64/libcanberra.so.0
#5  0x000055792c7cd07f in do_sound_action ()
#6  0x000055792c7cd6a9 in on_accelerator_activated ()
```

### 2. BlueZ / WirePlumber Socket & Endpoint Errors
Observed in `journalctl -b`:
```text
bluetoothd: profiles/audio/a2dp.c:load_remote_sep() Unable to load LastUsed: rseid 1 not found
bluetoothd: profiles/audio/a2dp.c:a2dp_select_capabilities() Unable to select SEP
bluetoothd: src/profile.c:ext_start_servers() RFCOMM server failed for Hands-Free unit: rfcomm_bind: Address already in use (98)
wireplumber: spa.bluez5.midi: org.bluez.GattManager1.RegisterApplication() failed: GDBus.Error:org.bluez.Error.AlreadyExists: Already Exists
```

---

## 🛠️ Recovery Procedures (No Reboot Needed)

### Immediate One-Step Fix
Run the recovery script included in this repository:
```bash
~/archConfig/troubleshoot/restore_audio_bluetooth_sleep.sh
# Or, if bluetoothd itself is wedged, restart BlueZ BEFORE user PipeWire/WirePlumber:
~/archConfig/troubleshoot/restore_audio_bluetooth_sleep.sh --restart-bluetooth
```

### Manual Recovery Commands
If recovering manually via terminal:
```bash
# 1. Restart user audio services to flush deadlocked WirePlumber & PipeWire sockets
systemctl --user restart pipewire pipewire-pulse wireplumber

# 2. Restart GNOME shortcuts daemon so it flushes any stalled event loop locks
systemctl --user restart org.gnome.SettingsDaemon.MediaKeys.target

# 3. Disconnect and reconnect the Bluetooth audio device
bluetoothctl disconnect <DEVICE_MAC>
sleep 1
bluetoothctl connect <DEVICE_MAC>

# 4. Verify PipeWire recognizes the audio sink
wpctl status
```

---

## 🛡️ Long-Term Mitigation & Prevention

### 1. Never Restart `bluetooth.service` in Isolation
If you ever restart the system Bluetooth daemon (`sudo systemctl restart bluetooth`), **always** restart user PipeWire/WirePlumber immediately after:
```bash
sudo systemctl restart bluetooth && systemctl --user restart wireplumber pipewire pipewire-pulse
```
`hardware-linux/bluetooth/setup.sh` and `troubleshoot/fix_intel_bluetooth_sco.sh` now automatically restart `$SUDO_USER`'s user audio stack whenever `bluetooth.service` is restarted.

### 2. Clean Sleep Hook + BlueZ `ResumeDelay = 3`
`hardware-linux/bluetooth/bluetooth-sleep.sh` records connected devices before suspend, disconnects them with a 0.5s settle window so AVDTP tears down cleanly, waits for `hci0` readiness on resume, powers on the adapter, and reconnects previously active devices after BlueZ/WirePlumber endpoints settle. `ResumeDelay = 3` in `/etc/bluetooth/main.conf` provides additional coexistence settling time on Intel CNVi hardware.

### 3. Disable Volume Change Sound Feedback (Protects Shortcuts)
To ensure that an audio server hang can **never** freeze your keyboard shortcuts (`Super + Return`, media keys, etc.), disable GNOME's audible feedback on volume key presses:
```bash
gsettings set org.gnome.desktop.sound input-feedback-sounds false
```
When this setting is `false`, `gsd-media-keys` does not invoke `libcanberra-pulse` synchronously on volume button presses, guaranteeing your keyboard shortcuts remain responsive even if audio is offline.
