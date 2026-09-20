#!/bin/bash

cat <<"EOF"
                                                      __ _
  __ _ _ __   ___  _ __ ___   ___     ___ ___  _ __  / _(_) __ _
 / _` | '_ \ / _ \| '_ ` _ \ / _ \   / __/ _ \| '_ \| |_| |/ _` |
| (_| | | | | (_) | | | | | |  __/  | (_| (_) | | | |  _| | (_| |
 \__, |_| |_|\___/|_| |_| |_|\___|___\___\___/|_| |_|_| |_|\__, |
 |___/                          |_____|                    |___/

EOF

# Unbind conflicting default navigation keys
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['']"

# Workspace navigation shortcuts (Super+Page_Up / Super+Page_Down)
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Super>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Super>Page_Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Super><Shift>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Super><Shift>Page_Down']"

# Workspace switching: Super + [1-9]
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>7']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>8']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "['<Super>9']"

# Move windows to workspace: Super + Shift + [1-9]
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Super><Shift>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Super><Shift>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Super><Shift>6']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Super><Shift>7']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Super><Shift>8']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "['<Super><Shift>9']"

# Remove application switching shortcuts (Super + [1-9])
gsettings set org.gnome.shell.keybindings switch-to-application-1 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-5 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-6 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-7 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-8 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-9 "[]"

# Screenshots
gsettings set org.gnome.shell.keybindings screenshot "['<Super><Shift>a']"
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Super><Shift>s', 'Print']"
gsettings set org.gnome.shell.keybindings screenshot-window "['<Super><Shift>w']"
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['<Super><Shift>a']" 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot "['<Super><Shift>s']" 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot "['<Super><Shift>w']" 2>/dev/null || true

# Change notifications management
gsettings set org.gnome.shell.keybindings focus-active-notification "[]"
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>n']"

# Unbind Dash-to-Dock (or Ubuntu Dock) shortcuts that conflict with Super+Q and workspace switching
if gsettings list-schemas | grep -q "org.gnome.shell.extensions.dash-to-dock"; then
    gsettings set org.gnome.shell.extensions.dash-to-dock shortcut "[]"
    gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-text "''"
    gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false
fi

# Window management
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-side-w '[]'
gsettings set org.gnome.desktop.wm.keybindings move-to-side-e '[]'
gsettings set org.gnome.desktop.wm.keybindings move-to-center "['<Super>c']"

# File Explorer / Nautilus shortcut
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

# Tiling Assistant - Center window
if gsettings list-schemas | grep -q "org.gnome.shell.extensions.tiling-assistant"; then
    gsettings set org.gnome.shell.extensions.tiling-assistant center-window "['<Super>c']"
    dconf write /org/gnome/shell/extensions/tiling-assistant/center-window "['<Super>c']"
fi

# Font settings
gsettings set org.gnome.desktop.interface font-name 'Ubuntu Nerd Font 11'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu Nerd Font 11'

# Terminal preferences and keyboard repeat
gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty' 2>/dev/null || true
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 10
gsettings set org.gnome.desktop.peripherals.keyboard delay 200

# Ptyxis optimizations
if gsettings list-schemas | grep -q "org.gnome.Ptyxis"; then
    gsettings set org.gnome.Ptyxis use-system-font true
    dconf write /org/gnome/Ptyxis/Shortcuts/move-next-tab "'<Control>Tab'"
    dconf write /org/gnome/Ptyxis/Shortcuts/move-previous-tab "'<Control><Shift>Tab'"
fi

# Prevent waking discrete NVIDIA GPU from D3cold suspend on terminal launch
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/dbus-1/services"

if [[ -d "$SCRIPT_DIR/ptyxis" ]]; then
    install -m 755 "$SCRIPT_DIR/ptyxis/ptyxis" "$HOME/.local/bin/ptyxis"
    sed "s|@HOME@|$HOME|g" "$SCRIPT_DIR/ptyxis/org.gnome.Ptyxis.service" > "$HOME/.local/share/dbus-1/services/org.gnome.Ptyxis.service"
    install -m 644 "$SCRIPT_DIR/ptyxis/org.gnome.Ptyxis.desktop" "$HOME/.local/share/applications/org.gnome.Ptyxis.desktop"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

# Clipboard Indicator (clipboard-indicator@tudmotu.com)
# Free Super+V from GNOME's default notification tray (remapped to Super+N above)
# and bind Super+V to toggle the clipboard history menu
CLIPBOARD_SCHEMAS="$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/schemas"
if [[ -d "$CLIPBOARD_SCHEMAS" ]]; then
    gsettings --schemadir "$CLIPBOARD_SCHEMAS" set org.gnome.shell.extensions.clipboard-indicator toggle-menu "['<Super>v']"
    gsettings --schemadir "$CLIPBOARD_SCHEMAS" set org.gnome.shell.extensions.clipboard-indicator enable-keybindings true
fi
dconf write /org/gnome/shell/extensions/clipboard-indicator/toggle-menu "['<Super>v']"

# Load gnome extensions if configuration exists
if [[ -f "$SCRIPT_DIR/gnome-extensions-settings.dconf" ]]; then
    dconf load /org/gnome/shell/extensions/ < "$SCRIPT_DIR/gnome-extensions-settings.dconf"
fi
