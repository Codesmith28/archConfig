# KDE Plasma Desktop Optimizations (Fedora)

This module delegates to the canonical KDE setup script at [`desktop/kde/setup.sh`](file:///home/codesmith28/archConfig/desktop/kde/setup.sh) to configure:

1. **Active Shortcuts & Keybindings (`kglobalshortcutsrc` & `kdeglobals`)**:
   - `Meta+Return`: Universal default terminal launcher (`default-terminal` -> Ghostty / Konsole)
   - `Meta+Q`: Close active window
   - `Meta+Up` / `Meta+Down`: Maximize / Minimize window
   - `Meta+C`: Move window to center
   - `Meta+1..4`: Direct workspace switching
   - `Meta+Shift+1..4`: Move window to workspace
   - `Meta+E`: Open Dolphin file manager
   - `Meta+V`: Open Klipper clipboard history popup
   - `Meta+Shift+S` / `Print`: Spectacle screenshot utility
   - `Alt+Space` / `Meta`: KRunner application launcher

2. **KWin Window Management & Behavior (`kwinrc`)**:
   - Titlebar button layout: Minimize, Maximize, Close on right (`ButtonsOnRight=IAX`), window menu on left (`ButtonsOnLeft=M`).
   - Virtual desktops: Configures 4 virtual workspaces out of the box.

3. **Input & Keyboard Responsiveness (`kcminputrc`)**:
   - Key repeat delay: `250ms`
   - Key repeat rate: `40Hz`
   - Touchpad: Tap-to-click and Natural scrolling enabled.

4. **KDE Discover & PackageKit Backend (`appstream`)**:
   - Enables RPM Fusion AppStream metadata and verifies `plasma-discover-packagekit` backend so native RPM packages appear alongside Flatpaks in KDE Discover.
