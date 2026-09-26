# GNOME & Terminal Optimizations

This module configures GNOME desktop settings, window management shortcuts, font preferences, and resolves high startup latency for the default terminal emulator (**Ptyxis**).

---

## 1. Ptyxis Terminal Fast Startup Optimization

### Problem
On hybrid dual-GPU laptops (Intel integrated graphics + NVIDIA discrete GPU), launching Ptyxis from a cold start took **~2.4 seconds**. 

GTK 4 uses Vulkan for hardware-accelerated rendering by default. During Vulkan initialization (`libvulkan.so`), the loader enumerates every Vulkan ICD on the system, including `/usr/share/vulkan/icd.d/nvidia_icd.json`. The NVIDIA driver queried `/dev/nvidiactl`, forcing the discrete NVIDIA GPU to wake up from `D3cold` / `suspended` low-power sleep. This caused a blocking ~2-second kernel/PCI delay before the terminal window could open.

### Solution
1. **Ptyxis Wrapper (`ptyxis/ptyxis`)**:
   Sets `VK_LOADER_DRIVERS_DISABLE="*nvidia*"` before launching Ptyxis. This instructs Vulkan to render via the Intel UHD GPU and ignore the NVIDIA ICD, preventing the discrete GPU from waking up.
   - Installed to: `~/.local/bin/ptyxis`
2. **DBus Service Override (`ptyxis/org.gnome.Ptyxis.service`)**:
   Ensures launching Ptyxis via GNOME Shell DBus activation routes through `~/.local/bin/ptyxis`.
   - Installed to: `~/.local/share/dbus-1/services/org.gnome.Ptyxis.service`
3. **Desktop Entry (`ptyxis/org.gnome.Ptyxis.desktop`)**:
   Ensures shortcuts (`Ctrl+Alt+T` via `xdg-terminal-exec`) and application launcher icons invoke the wrapper.
   - Installed to: `~/.local/share/applications/org.gnome.Ptyxis.desktop`
4. **Shell GPU Preservation (`.bashrc` & `.profile`)**:
   Both `~/.bashrc` and `~/.profile` automatically unset `VK_LOADER_DRIVERS_DISABLE` so that all shell sessions retain full, unrestricted access to CUDA, PyTorch, Vulkan, and the NVIDIA GPU.

### Results
- **Cold start latency**: Reduced from **~2.40s** to **~0.31s** (~8x faster).
- **Power savings**: NVIDIA discrete GPU stays in `suspended` power-saving mode instead of spinning fans and drawing battery power on terminal launch.

---

## 2. Key GNOME Extensions & Multi-Distro Packages

`setup.sh` automatically installs `gnome-tweaks` and `extension-manager` across Fedora, Ubuntu, and Arch, and provisions the 5 canonical GNOME extensions:
1. **Blur my Shell** (`blur-my-shell@aunetx`): Blur effect for top panel, dash, overview, and app folders.
2. **Clipboard Indicator** (`clipboard-indicator@tudmotu.com`): Clipboard history manager mapped to `Super + V`.
3. **Compiz Alike Magic Lamp Effect** (`compiz-alike-magic-lamp-effect@hermes83.github.com`): Fluid window minimize animation.
4. **Dash to Dock** (`dash-to-dock@micxgx.gmail.com`): Centered bottom dock with autohide, running dots, and conflicting shortcuts disabled.
5. **Rounded Window Corners Reborn** (`rounded-window-corners@fxgn`): Consistent rounded window borders for all applications.

---

## 3. GNOME Desktop & Window Management

`setup.sh` applies the following workflow customizations:

- **Workspace Navigation**:
  - `Super + Page_Up` / `Page_Down`: Switch workspaces.
  - `Super + 1..9`: Jump directly to workspace 1–9.
  - `Super + Shift + 1..9`: Move window to workspace 1–9.
  - `Super + End` / `Super + Shift + End`: Switch / move window to last workspace.
- **Application Launchers & Shortcuts**:
  - `Super + Return`: Open default terminal emulator (Ghostty / configured GNOME default terminal).
  - `Super + E`: Open Nautilus file manager.
  - `Super + Shift + B`: Open default web browser.
- **Window Management**:
  - `Super + Q`: Close active window (replaces `Alt + F4`).
  - `Super + M`: Minimize active window.
  - `Super + C`: Center active window.
  - Titlebar Buttons: `appmenu:minimize,maximize,close`.
- **Screenshots**:
  - `Super + Shift + S` / `Print`: Interactive screenshot UI.
  - `Super + Shift + A`: Screenshot area.
  - `Super + Shift + W`: Screenshot window.
- **Notifications & Clipboard**:
  - `Super + N`: Toggle notification tray.
  - `Super + V`: Toggle Clipboard Indicator history.
- **Fonts & Interface**:
  - System UI font: `Adwaita Sans 11`.
  - Monospace font: `JetBrainsMono Nerd Font 10`.
  - Dark mode (`prefer-dark`), blue accent, 24h clock, and battery percentage display enabled.
- **Keyboard & Touchpad**:
  - Repeat rate: 250ms delay, 25ms repeat interval (~40Hz).
  - Touchpad: Disable While Typing (DWT) enabled, tap-to-click, and natural scrolling.
- **Ptyxis Tab Switching**:
  - `Ctrl + Tab`: Next tab.
  - `Ctrl + Shift + Tab`: Previous tab.

---

## Installation & Verification

To apply all configurations:

```bash
./setup.sh
```
