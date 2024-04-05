#!/bin/bash

cat <<"EOF"
 _                 _          _     
| |__   ___   ___ | | __  ___| |__  
| '_ \ / _ \ / _ \| |/ / / __| '_ \ 
| | | | (_) | (_) |   < _\__ \ | | |
|_| |_|\___/ \___/|_|\_(_)___/_| |_|
                                    

EOF

# to be put in dotfiles-versions directory 

# alacritty:
rm -rf ~/dotfiles-versions/$version/starship/starship.toml
rm -rf ~/dotfiles-versions/$version/alacritty

# hypr:
rm -rf ~/dotfiles-versions/$version/hypr/hyprlock.conf

# hypr/conf:
rm -rf ~/dotfiles-versions/$version/hypr/conf/keyboard.conf
rm -rf ~/dotfiles-versions/$version/hypr/conf/layout.conf

# hypr/scripts:
rm -rf ~/dotfiles-versions/$version/hypr/scripts/screenshot.sh 
