#!/bin/bash

# unbind shfit+ctrl+alt+arrow keys using gsettings
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['']"

# open new windows in the center:
gsettings set org.gnome.mutter center-new-windows true
