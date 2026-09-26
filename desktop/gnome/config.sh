#!/usr/bin/env bash
# ==============================================================================
# GNOME Configuration Script (Keybindings, Preferences & Dconf Loader)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# 1. Load Dconf Settings Profile (if available)
# ------------------------------------------------------------------------------
DCONF_FILE="$SCRIPT_DIR/dconf/gnome-settings.dconf"
if [[ -f "$DCONF_FILE" ]] && command -v dconf >/dev/null 2>&1; then
    dconf load / < "$DCONF_FILE" || true
fi

# ------------------------------------------------------------------------------
# 2. Workspace Navigation & Management Shortcuts
# ------------------------------------------------------------------------------
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>Page_Down']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Super>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Super>Page_Down']"

gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Super><Shift>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Super><Shift>Page_Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Super><Shift>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Super><Shift>Page_Down']"

gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "['<Super>End']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "['<Super><Shift>End']"

# Workspace switching & window moving: Super + [1-9] / Super + Shift + [1-9]
for i in {1..9}; do
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']"
    gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
done

# ------------------------------------------------------------------------------
# 3. Screenshots & Notifications
# ------------------------------------------------------------------------------
gsettings set org.gnome.shell.keybindings screenshot "['<Super><Shift>a']"
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Super><Shift>s', 'Print']"
gsettings set org.gnome.shell.keybindings screenshot-window "['<Super><Shift>w']"

gsettings set org.gnome.shell.keybindings focus-active-notification "[]"
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>n']"

# ------------------------------------------------------------------------------
# 4. Dash-to-Dock Shortcuts & Placement
# ------------------------------------------------------------------------------
DASH_TO_DOCK_USER="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas"
if [[ -d "$DASH_TO_DOCK_USER" ]]; then
    gsettings --schemadir "$DASH_TO_DOCK_USER" set org.gnome.shell.extensions.dash-to-dock shortcut "[]" 2>/dev/null || true
    gsettings --schemadir "$DASH_TO_DOCK_USER" set org.gnome.shell.extensions.dash-to-dock shortcut-text "''" 2>/dev/null || true
    gsettings --schemadir "$DASH_TO_DOCK_USER" set org.gnome.shell.extensions.dash-to-dock hot-keys false 2>/dev/null || true
fi

if gsettings list-schemas 2>/dev/null | grep -q "^org\.gnome\.shell\.extensions\.dash-to-dock$"; then
    gsettings set org.gnome.shell.extensions.dash-to-dock shortcut "[]" 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-text "''" 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false 2>/dev/null || true
fi

dconf write /org/gnome/shell/extensions/dash-to-dock/hot-keys false 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/shortcut "@as []" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/shortcut-text "''" 2>/dev/null || true
for i in {1..9}; do
    dconf write /org/gnome/shell/extensions/dash-to-dock/app-shift-hotkey-$i "@as []" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/dash-to-dock/app-hotkey-$i "@as []" 2>/dev/null || true
done
dconf write /org/gnome/shell/extensions/dash-to-dock/app-shift-hotkey-10 "@as []" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/app-hotkey-10 "@as []" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. Window Management & Titlebar Buttons
# ------------------------------------------------------------------------------
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"
gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']"
gsettings set org.gnome.desktop.wm.keybindings move-to-side-w '[]'
gsettings set org.gnome.desktop.wm.keybindings move-to-side-e '[]'
gsettings set org.gnome.desktop.wm.keybindings move-to-center "['<Super>c']"
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.mutter dynamic-workspaces true

# ------------------------------------------------------------------------------
# 6. Application Launchers & Media Keys
# ------------------------------------------------------------------------------
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super><Shift>b']"

if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.tiling-assistant"; then
    gsettings set org.gnome.shell.extensions.tiling-assistant center-window "['<Super>c']" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/tiling-assistant/center-window "['<Super>c']" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 7. Font Settings
# ------------------------------------------------------------------------------
gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11' 2>/dev/null || true
gsettings set org.gnome.desktop.interface document-font-name 'Adwaita Sans 11' 2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. Appearance & Peripherals
# ------------------------------------------------------------------------------
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface accent-color 'blue' 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-show-seconds false 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-show-weekday false 2>/dev/null || true
gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true 2>/dev/null || true

gsettings set org.gnome.desktop.peripherals.keyboard repeat true
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25

gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true

# ------------------------------------------------------------------------------
# 9. Clipboard Indicator
# ------------------------------------------------------------------------------
CLIPBOARD_SCHEMAS="$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/schemas"
if [[ -d "$CLIPBOARD_SCHEMAS" ]]; then
    gsettings --schemadir "$CLIPBOARD_SCHEMAS" set org.gnome.shell.extensions.clipboard-indicator toggle-menu "['<Super>v']" 2>/dev/null || true
    gsettings --schemadir "$CLIPBOARD_SCHEMAS" set org.gnome.shell.extensions.clipboard-indicator enable-keybindings true 2>/dev/null || true
fi
dconf write /org/gnome/shell/extensions/clipboard-indicator/toggle-menu "['<Super>v']" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/clipboard-indicator/enable-keybindings true 2>/dev/null || true

echo "GNOME configurations applied successfully!"
