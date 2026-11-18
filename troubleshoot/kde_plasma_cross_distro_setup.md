# Troubleshooting: KDE Plasma 6 Cross-Distro Setup & Shortcut Persistence

## Problem Overview
When bootstrapping dotfiles or migrating KDE Plasma across **Fedora (Plasma 6)**, **Arch Linux (Plasma 6)**, and **Ubuntu (Plasma 5/6)**, global shortcuts and custom launchers frequently fail to persist or trigger out-of-the-box. Common symptoms:
- Global shortcuts reset to defaults or disappear after reboot/logout.
- Custom keybindings (e.g., `<Super>Return` for terminal, `<Super>b` for browser) do nothing.
- Running setup scripts with `sudo` corrupts file permissions or writes to `/root/`.
- Pressing the `Super` (Windows) key alone fails to open the Application Launcher.
- Discrepancies between Qt5/KF5 and Qt6/KF6 package tools break automated provisioning.

---

## Root Causes Diagnosed

### 1. Root Execution & Missing DBus Session
- **The Issue**: Executing scripts with `sudo` causes configurations to write to `/root/.config/kglobalshortcutsrc`. If run without an active graphical session, `DBUS_SESSION_BUS_ADDRESS` is missing, preventing shortcut registration.
- **The Fix**: The automated installer drops root privileges to the desktop session user and connects directly to `/run/user/<uid>/bus` or initializes a headless bus via `dbus-run-session`.

### 2. In-Memory KGlobalAccel Cache Overwrites
- **The Issue**: Modifying `~/.config/kglobalshortcutsrc` purely on disk while the `kglobalaccel` daemon runs in memory causes changes to be overwritten when KDE flushes its cache on logout.
- **The Fix**: Shortcuts must be committed directly to the running `kglobalaccel` daemon via D-Bus API calls (`org.kde.KGlobalAccel` `/kglobalaccel` `setShortcut`), followed by syncing to disk.

### 3. Toolchain & Package Name Divergence (KF5 vs KF6)
- **The Issue**: Binary and package names differ across distributions and Plasma versions:
  - Fedora: `kf6-kconfig` (`kwriteconfig6`), `qt6-qttools` (`qdbus-qt6`), `python3-dbus`.
  - Arch Linux: `qt6-tools` (`qdbus-qt6`), `python-dbus`.
  - Ubuntu: `qdbus-qt6` (or `qdbus`), `python3-dbus`.
- **The Fix**: Dynamic package resolution and tool fallbacks (`kwriteconfig6` -> `kwriteconfig5`, `qdbus-qt6` -> `qdbus`).

### 4. GUI Subshell PATH Disconnect
- **The Issue**: KDE Plasma launchers and KWin run as systemd user services, not interactive login shells. Custom scripts in `~/.local/bin/` (e.g., `default-terminal`, `powerprofile`) fail with "command not found".
- **The Fix**: Persist PATH into `~/.config/environment.d/10-archconfig.conf` and import it into the live session via `systemctl --user import-environment PATH`.

### 5. Custom Command Registration (`.desktop` Requirements)
- **The Issue**: KDE Plasma 6 requires custom executable shortcuts to be backed by a valid `.desktop` file containing `X-KDE-GlobalAccel-CommandShortcut=true`.
- **The Fix**: Deploy desktop entries to `~/.local/share/applications/` and refresh the desktop MIME database.

### 6. Meta / Super Key Modifier Interception
- **The Issue**: The standalone `Meta` key trigger for the application menu requires explicit configuration in `kwinrc` under `[ModifierOnlyShortcuts]`.
- **The Fix**: Set `Meta=org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu` in `~/.config/kwinrc`.

---

## Quick Fix (Automated Script)

Run the universal KDE setup script from the repository root:
```bash
./desktop/kde/setup.sh
```

This automated script:
- Detects the active distro and installs missing DBus / Qt6 utilities.
- Drops privileges safely if invoked with `sudo`.
- Deploys GUI PATH persistence to `~/.config/environment.d/`.
- Provisions desktop launcher entries for default terminal, browser, and dark mode toggle.
- Commits universal shortcuts directly via D-Bus to `kglobalaccel`.
- Runs a built-in 30+ point verification checklist.

---

## Manual Distro-Specific Setup & Runbook

### Step 1: Install Distro Prerequisites
Ensure required D-Bus and Qt CLI packages are installed:

- **Fedora**:
  ```bash
  sudo dnf install -y python3-dbus qt6-qttools kf6-kconfig
  ```
- **Arch Linux**:
  ```bash
  sudo pacman -S --needed python-dbus qt6-tools
  ```
- **Ubuntu**:
  ```bash
  sudo apt update && sudo apt install -y python3-dbus qdbus-qt6
  ```

---

### Step 2: Ensure GUI PATH Persistence
Export `~/.local/bin` to systemd user services:
```bash
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/10-archconfig.conf << 'EOF'
PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
EOF

systemctl --user import-environment PATH
```

---

### Step 3: Register Custom App Desktop Entries
Create `.desktop` files with KDE global shortcut attributes:

```bash
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/default-terminal.desktop << 'EOF'
[Desktop Entry]
Name=Default Terminal
Exec=default-terminal
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
X-KDE-GlobalAccel-CommandShortcut=true
StartupNotify=true
EOF

update-desktop-database ~/.local/share/applications
```

---

### Step 4: Configure Meta Key Menu Trigger
Enable single-key `Meta` to open the launcher menu:
```bash
kwriteconfig6 --file ~/.config/kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu" || \
kwriteconfig5 --file ~/.config/kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu"

# Reload KWin configuration live
qdbus-qt6 org.kde.KWin /KWin reconfigure 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure
```

---

### Step 5: Reload Shortcut Services
If shortcuts are out of sync, restart the user daemon:
```bash
systemctl --user restart plasma-kglobalaccel.service
```

---

## Verification & Diagnostics

### 1. Run Automated Repository Self-Test
```bash
./desktop/kde/setup.sh
```
All checks should report `✓` (Application Launcher, Terminal Shortcut, Window Close, Workspaces, Krohnkite).

### 2. Verify Active Shortcut Registration
Query `kglobalaccel` via D-Bus:
```bash
# Check terminal launch shortcut
qdbus-qt6 org.kde.kglobalaccel /kglobalaccel getShortcut default-terminal.desktop _launch 2>/dev/null || \
qdbus org.kde.kglobalaccel /kglobalaccel getShortcut default-terminal.desktop _launch
```

### 3. Verify GUI Environment PATH
```bash
systemctl --user show-environment | grep PATH
```
Confirm `$HOME/.local/bin` is present at the beginning of `PATH`.
