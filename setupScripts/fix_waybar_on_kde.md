We'll **create a user-specific override** for `waybar.service` that adds a condition to run **only in Hyprland sessions**.

---

### Step-by-Step:

#### 1. Create an override directory

```bash
systemctl --user edit waybar.service
```

```ini
[Service]
# Clear previous ExecStart (precaution, not strictly needed here)
ExecStart=

# Set the command again
ExecStart=/usr/bin/waybar

[Unit]
# Only start Waybar if running under Hyprland
ConditionEnvironment=XDG_CURRENT_DESKTOP=Hyprland
```

Then save and exit.

---

#### 2. Reload systemd user daemon

```bash
systemctl --user daemon-reexec
systemctl --user daemon-reload
```

---

#### 3. Restart the service (optional)

```bash
systemctl --user restart waybar.service
```

You’re done! ✅

Now, **Waybar will only autostart in Hyprland sessions**, not KDE or anything else.
