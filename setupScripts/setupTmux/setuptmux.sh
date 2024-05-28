cat <<"EOF"
 _
| |_ _ __ ___  _   ___  __
| __| '_ ` _ \| | | \ \/ /
| |_| | | | | | |_| |>  <
 \__|_| |_| |_|\__,_/_/\_\


EOF

#! /bin/bash
# These are the configurations of omerxx for tmux!
echo "Thank you omerxx's for your tmux configurations!"

# Installing tmux and tpm
yay -S tmux
touch ~/.tmux.conf

echo "set -g prefix ^A

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

run '~/.tmux/plugins/tpm/tpm'" > ~/.tmux.conf 

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Copy from the dotfiles and then hit Ctrl+I"
