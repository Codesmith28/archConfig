# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# ------------------------------------------------------------------------------
# 1. Early Return for Non-Interactive Shells
# ------------------------------------------------------------------------------
case $- in
    *i*) ;;
      *) return ;;
esac

BASHRC_SOURCED=1

# ------------------------------------------------------------------------------
# 2. History & Shell Options
# ------------------------------------------------------------------------------
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# Make less more friendly for non-text input files (see lesspipe(1))
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ------------------------------------------------------------------------------
# 3. Environment & Profile Synchronization
# ------------------------------------------------------------------------------
# Source ~/.profile if not already in progress, guaranteeing fresh env on reload
if [ -z "$_SOURCING_PROFILE" ] && [ -f "$HOME/.profile" ]; then
    _SOURCING_BASHRC=1
    . "$HOME/.profile"
    unset _SOURCING_BASHRC _SOURCING_PROFILE
fi

# ------------------------------------------------------------------------------
# 4. Terminal Prompt & Title (Fallback when Starship is not used)
# ------------------------------------------------------------------------------
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color | *-256color) color_prompt=yes ;;
esac

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
    xterm* | rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
esac

# ------------------------------------------------------------------------------
# 5. Modular Bash Configuration (~/.bashrc.d)
# ------------------------------------------------------------------------------
if [ -d "$HOME/.bashrc.d" ]; then
    for rc_file in "$HOME/.bashrc.d"/*.bash; do
        [ -r "$rc_file" ] && . "$rc_file"
    done
    unset rc_file
fi

# Support for optional ~/.bash_aliases
if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
