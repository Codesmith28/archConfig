#!/bin/bash

cat <<"EOF"
                                                      __ _
  __ _ _ __   ___  _ __ ___   ___     ___ ___  _ __  / _(_) __ _
 / _` | '_ \ / _ \| '_ ` _ \ / _ \   / __/ _ \| '_ \| |_| |/ _` |
| (_| | | | | (_) | | | | | |  __/  | (_| (_) | | | |  _| | (_| |
 \__, |_| |_|\___/|_| |_| |_|\___|___\___\___/|_| |_|_| |_|\__, |
 |___/                          |_____|                    |___/

EOF

# unbind shfit+ctrl+alt+arrow keys using gsettings
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['']"

# Copy up down
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Super>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Super>Page_Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Super><Shift>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Super><Shift>Page_Down']"

# Workspace swithcing  super + number
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>7']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>8']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "['<Super>9']"

# Move windows to workspace using super + shift + number
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Super><Shift>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Super><Shift>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Super><Shift>6']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Super><Shift>7']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Super><Shift>8']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "['<Super><Shift>9']"

# Screenshots
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['<Super><Shift>a']"
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot "['<Super><Shift>s']"
gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot "['<Super><Shift>w']"

# Change notifications management
gsettings set org.gnome.desktop.wm.keybindings focus-active-notification "[]"
gsettings set org.gnome.desktop.wm.keybindings show-notification-list "['<Super>n']"

# Window manaegement
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"
gsettings set org.gnome.desktop.wm.keybindings move-to-side-w '[]'
gsettings set org.gnome.desktop.wm.keybindings move-to-side-e '[]'

# Load gnome extensions:
dconf load /org/gnome/shell/extensions/ <./gnome-extensions-settings.dconf
