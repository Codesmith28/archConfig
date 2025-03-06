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

gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Super>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Super>Page_Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Super><Shift>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Super><Shift>Page_Down']"

# open new windows in the center:
gsettings set org.gnome.mutter center-new-windows true
