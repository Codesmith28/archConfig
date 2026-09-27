# Troubleshooting: GNOME Cross-Distro Setup & Out-of-the-Box Stability

## Problem Overview
Across different Linux distributions (**Fedora, Ubuntu, Arch Linux**), GNOME desktop configurations, keybindings, and extensions often fail to apply cleanly out-of-the-box when bootstrapping or migrating dotfiles. Users frequently report having to manually configure shortcuts, re-enable extensions in Extension Manager, or re-apply themes.

---

## Root Causes Diagnosed

### 1. Root Privilege & DBus Session Detachment
- **The Issue**: Running a bootstrap or setup script with `sudo` causes `gsettings` and `dconf` to write directly to `/root/.config/dconf/user` instead of `/home/<user>/.config/dconf/user`. Furthermore, when executed over SSH, TTY, or before the graphical desktop starts, `DBUS_SESSION_BUS_ADDRESS` is absent, causing `dconf` to abort with `failed to commit changes to dconf: Cannot autolaunch D-Bus without X11 $DISPLAY`.
- **The Fix**: [`desktop/gnome/setup.sh`](file:///home/codesmith28/archConfig/desktop/gnome/setup.sh) automatically inspects the caller. If invoked with `sudo` or as root, it drops privileges to the active desktop session user (using `DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/<uid>/bus"`). If no active DBus bus is running, it spawns a headless bus via `dbus-run-session` so dconf writes directly to the user's database.

### 2. Extension Version Gating & Master Toggle
- **The Issue**: By default, GNOME Shell checks extension metadata for exact GNOME version compatibility. Whenever GNOME receives a minor or major point update (e.g. 46 to 47 or 50), extensions without the new version tag are automatically disabled. In addition, after any shell crash, GNOME may set `disable-user-extensions = true`.
- **The Fix**: The setup script permanently sets:
  ```bash
  gsettings set org.gnome.shell disable-user-extensions false
  gsettings set org.gnome.shell disable-extension-version-validation true
  ```

### 3. Ubuntu-Specific Dock Conflicts
- **The Issue**: Ubuntu ships with `ubuntu-dock@ubuntu.com` enabled by default. Installing `dash-to-dock@micxgx.gmail.com` without disabling `ubuntu-dock` causes double docks, overlapping icon bars, or settings overrides.
- **The Fix**: The setup script detects `ubuntu-dock` and explicitly disables it (`gnome-extensions disable ubuntu-dock@ubuntu.com`) while applying the canonical dock settings.

### 4. Uncompiled GSettings Extension Schemas
- **The Issue**: Extensions downloaded from `extensions.gnome.org` into `~/.local/share/gnome-shell/extensions/<uuid>/` bundle XML schemas in `schemas/`. If `glib-compile-schemas` is not executed on that directory, GNOME Shell and `gsettings` cannot read/write settings, throwing missing schema errors or crashing the extension preferences.
- **The Fix**: The setup script automatically iterates over every installed extension directory and executes `glib-compile-schemas "$ext_dir/schemas"`.

### 5. Shortcut Collision Matrix
- **The Issue**: Default GNOME Shell shortcuts intercept keys intended for custom workflows:
  - `<Super>1` through `<Super>9`: Defaults to `switch-to-application-[1-9]`, conflicting with workspace switching.
  - Dash-to-Dock / Ubuntu-Dock: Hooks `<Super>1`..`<Super>9` via `app-hotkey-[1-10]`.
  - `<Super>V`: Bound by default to `toggle-message-tray` or `focus-active-notification`, intercepting the Clipboard Indicator shortcut.
- **The Fix**: The setup script unbinds all colliding defaults:
  - Clears `org.gnome.shell.keybindings switch-to-application-[1-9]` -> `[]`.
  - Clears `dash-to-dock` `app-hotkey-[1-10]` and `app-shift-hotkey-[1-10]`.
  - Rebinds notification tray to `<Super>n`.
  - Rebinds `<Super>v` to `clipboard-indicator toggle-menu`.

### 6. GUI PATH Environment Disconnect
- **The Issue**: GNOME Shell and systemd user services run outside of interactive login shells (`.bashrc` / `.zshrc`). Custom launcher scripts like `default-terminal` in `~/.local/bin` fail with "command not found" when triggered by keybindings (`<Super>Return`).
- **The Fix**: The setup script writes `~/.config/environment.d/10-archconfig.conf`:
  ```ini
  PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
  ```
  and imports it into the live systemd session via `systemctl --user import-environment PATH`.

### 7. Package Manager & Sudo Interactivity (`gnome-tweaks`)
- **The Issue**: `desktop/gnome/setup.sh` checked `can_sudo` using `sudo -n true` (passwordless check) and redirected errors to `2>/dev/null`. On fresh installations where sudo credentials were not already cached, `sudo -n true` failed, causing package installation (`gnome-tweaks`, `gnome-extensions-app`) to be silently skipped. In addition, stderr redirection suppressed the interactive password prompt.
- **The Fix**: Unified under `run_root()`. If run under `sudo`, packages are installed before dropping privileges. If run as a normal user, `sudo` is called directly without `sudo -n` or suppressing stderr, cleanly prompting the user.

### 8. Rounded Window Blur Support (`gnome-rounded-blur`)
- **The Issue**: `blur-my-shell` and `dash-to-dock` require mutter rounded blur libraries on Fedora for hardware-accelerated rounded blur effects.
- **The Fix**: Automatically enabled the COPR repository and installed the package:
  ```bash
  sudo dnf copr enable -y aneagle/gnome-rounded-blur
  sudo dnf install -y gnome-rounded-blur
  ```

### 9. Preserving Native Theme & Color Scheme
- **The Issue**: The setup script previously forced `color-scheme='prefer-dark'` and failed verification if the user was using a light or system-default appearance.
- **The Fix**: Removed forced dark mode override from `desktop/gnome/setup.sh`, `desktop/gnome/config.sh`, and `desktop/gnome/dconf/gnome-settings.dconf`. The user's active theme and color-scheme preference are preserved intact.

### 10. Extension Discovery & Session Lifecycle
- **The Issue**: When extensions are downloaded and extracted directly into `~/.local/share/gnome-shell/extensions/<uuid>`, GNOME Shell's running process does not discover newly created extension directories until the session is reloaded.
- **The Fix**: Documented and flagged that on a fresh VM or initial dotfile setup, a single session logout and log back in (or Wayland/X11 session restart) is required for GNOME Shell to index and enable the extensions.

### 11. User Fonts Directory Provisioning (`~/.local/share/fonts`)
- **The Issue**: Fresh Linux installations do not provide `~/.local/share/fonts` by default, leaving users with nowhere to drop downloaded Nerd Fonts (`.ttf`/`.otf`).
- **The Fix**: Added automatic creation of `~/.local/share/fonts` to `sync.sh`, `desktop/gnome/setup.sh`, and `core/config/fontconfig/setup.sh`.

---

## Verification & Diagnostic Commands

Run the built-in diagnostic verification:
```bash
./desktop/gnome/setup.sh
```

Or verify individual subsystems manually:

### 1. Check Extension States
```bash
gnome-extensions list --enabled
```
Expected output:
- `blur-my-shell@aunetx`
- `clipboard-indicator@tudmotu.com`
- `compiz-alike-magic-lamp-effect@hermes83.github.com`
- `dash-to-dock@micxgx.gmail.com`
- `rounded-window-corners@fxgn`

### 2. Verify Keybindings
```bash
# Window controls
gsettings get org.gnome.desktop.wm.keybindings close          # Expected: ['<Super>q', '<Alt>F4']
gsettings get org.gnome.desktop.wm.keybindings minimize       # Expected: ['<Super>m']
gsettings get org.gnome.desktop.wm.keybindings move-to-center # Expected: ['<Super>c']
gsettings get org.gnome.desktop.wm.preferences button-layout  # Expected: 'appmenu:minimize,maximize,close'

# Workspaces
gsettings get org.gnome.desktop.wm.keybindings switch-to-workspace-1 # Expected: ['<Super>1']
gsettings get org.gnome.desktop.wm.keybindings move-to-workspace-1   # Expected: ['<Super><Shift>1']

# Terminal launcher
gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings
```

### 3. Check Systemd GUI Environment
```bash
systemctl --user show-environment | grep PATH
```
Expected: Contains `/home/<user>/.local/bin`.
