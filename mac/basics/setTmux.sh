#!/bin/bash

# 1. Create the directory if it doesn't exist
mkdir -p ~/.tmux/plugins/tpm

# 2. Clone TPM only if it's not already there
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# 3. Use '>>' to append, or check if the line exists to avoid duplicates
cat <<EOT >>~/.tmux.conf

# TPM Configuration
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
EOT

echo "Installation complete. Restart tmux and press 'Prefix + I' to install plugins."
