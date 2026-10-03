# Troubleshooting: Bluetooth Audio Failure & GNOME Shortcuts Lockup After Sleep

## Symptoms
After waking the system from sleep/suspend:
1. **Bluetooth connects without audio**: The headset (e.g. OnePlus Nord Buds 4 Pro) shows as connected in Bluetooth settings, but audio continues playing through laptop speakers or no audio plays at all.
2. **Volume buttons (Vol +/-) stop working**: Pressing the hardware volume up/down or mute keys produces no volume changes and no on-screen display (OSD) feedback.
3. **`Super + Return` (Ghostty terminal) does not work**: Pressing the custom shortcut to launch the default terminal emulator is completely ignored.

---

## 🔍 Root Cause Analysis: The Cascade of Failure

The problem is not three separate bugs, but a **cascading domino failure** triggered across the kernel, audio daemon, and GNOME settings daemon.

```
+-----------------------------------------------------------------------------------+
| 1. System Wakes from Sleep                                                        |
|    - Intel AX211 Bluetooth USB root hub resets abruptly on resume.                |
|    - Headset reconnects via AVRCP (controls), but WirePlumber holds stale A2DP    |
|      transport endpoint (/org/bluez/hci0/.../sep1/fd0).                           |
+----------------------------------------+------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| 2. Audio Profile Fails                                                            |
|    - bluetoothd reports: "a2dp-source profile connect failed: Device or busy"     |
|    - WirePlumber logs: "Multiple sound server instances are probably trying to    |
|      use Bluetooth audio at the same time."                                       |
+----------------------------------------+------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| 3. Fatal Restart of bluetooth.service                                             |
|    - When bluetooth.service restarts while WirePlumber is running, WirePlumber    |
|      attempts to re-bind its BlueZ endpoints without closing old sockets:         |
|      "spa.bluez5.native: listen(): Address already in use"                        |
|      "RegisterProfile() failed: org.bluez.Error.NotPermitted"                     |
|    - WirePlumber DEADLOCKS. All PipeWire IPC (e.g. wpctl status) hangs indefinitely.|
+----------------------------------------+------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| 4. User Presses Volume Keys                                                       |
|    - gsd-media-keys intercepts XF86AudioRaiseVolume/LowerVolume.                  |
|    - It attempts to play the audio feedback beep via libcanberra-pulse.           |
|    - libcanberra-pulse calls pa_threaded_mainloop_wait() to reach pipewire-pulse. |
|    - Because pipewire-pulse is stuck waiting on WirePlumber,                      |
|      gsd-media-keys blocks forever in pthread_cond_wait().                        |
+----------------------------------------+------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| 5. All Custom Shortcuts Die (Super + Return)                                      |
|    - In GNOME, custom shortcuts configured in org.gnome.settings-daemon.plugins.  |
|      media-keys.custom-keybindings (e.g. default-terminal) are executed by        |
|      gsd-media-keys, NOT directly by mutter or gnome-shell.                       |
|    - With gsd-media-keys main event loop frozen on audio feedback, all shortcuts  |
|      are blocked from executing.                                                  |
+-----------------------------------------------------------------------------------+
```

---

## 🔬 Evidence & Diagnostic Traces

### 1. `gsd-media-keys` Deadlock Trace
Attaching `gdb` to `gsd-media-keys` during the frozen state revealed the exact blocking call in Thread 1:
```text
#0  0x00007f8cad5f3352 in __syscall_cancel_arch () from /lib64/libc.so.6
#1  0x00007f8cad5ea0ec in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libc.so.6
#2  0x00007f8cada3e7af in pa_threaded_mainloop_wait () from /lib64/libpulse.so.0
#3  0x00007f8cac3b0848 in pulse_driver_open () from /usr/lib64/libcanberra-0.30/libcanberra-pulse.so
#4  0x00007f8cade367b6 in ca_context_play_full () from /lib64/libcanberra.so.0
#5  0x000055792c7cd07f in do_sound_action ()
#6  0x000055792c7cd6a9 in on_accelerator_activated ()
```
The thread was indefinitely waiting for PulseAudio emulation (`pipewire-pulse`) to answer the feedback sound request.

### 2. WirePlumber Socket Collision
Journal logs from `wireplumber`:
```text
wireplumber: spa.bluez5.native: listen(): Address already in use
wireplumber: spa.bluez5.native: RegisterProfile() failed: org.bluez.Error.NotPermitted
```
`wpctl status` timed out with exit code `124` because WirePlumber was unresponsive.

---

## 🛠️ Recovery Procedures (No Reboot Needed)

### Immediate One-Step Fix
Run the recovery script included in this repository:
```bash
~/archConfig/troubleshoot/restore_audio_bluetooth_sleep.sh
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
sudo systemctl restart bluetooth && systemctl --user restart wireplumber
```
Leaving WirePlumber running while BlueZ restarts triggers the upstream `spa.bluez5.native: listen(): Address already in use` bug.

### 2. Disable Volume Change Sound Feedback (Protects Shortcuts)
To ensure that an audio server hang can **never** freeze your keyboard shortcuts (`Super + Return`, media keys, etc.), disable GNOME's audible feedback on volume key presses:
```bash
gsettings set org.gnome.desktop.sound input-feedback-sounds false
```
When this setting is `false`, `gsd-media-keys` does not invoke `libcanberra-pulse` synchronously on volume button presses, guaranteeing your keyboard shortcuts remain responsive even if audio is offline.
