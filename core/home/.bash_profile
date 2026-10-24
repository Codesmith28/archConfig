# ~/.bash_profile: executed by bash(1) for login shells.
# Universal cross-distro loader (Fedora, macOS, Ubuntu Server, Arch)

# 1. Source ~/.profile for environment variables and PATH
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# 2. Source ~/.bashrc for interactive shell aliases, prompt, and functions
if [ -f "$HOME/.bashrc" ] && [ -z "$BASHRC_SOURCED" ]; then
    . "$HOME/.bashrc"
fi


# Ensure ~/.local/bin is available in login shells
export PATH="$HOME/.local/bin:$PATH"
