# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

PROFILE_SOURCED=1

# if running bash   
if [ -n "$BASH_VERSION" ] && [ -z "$BASHRC_SOURCED" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# editor
export EDITOR='nvim'

# editing configs:
alias confb='$EDITOR ~/.bashrc'
alias confp='$EDITOR ~/.profile'
alias confn='$EDITOR ~/.config/nvim/'
alias confg='$EDITOR ~/.config/ghostty/config'

# sourcing
alias sourceb='source ~/.bashrc'
alias source_venv='source ./venv/bin/activate'

# shell:
alias c='clear'
alias e='exit'

# navigation
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons'
    alias ll='eza -l --icons'
    alias la='eza -a --icons'
    alias lla='eza -al --icons'
    function lt() {
        local level=${1:-1}
        eza -a --tree --level="$level" --icons
    }
fi
alias pj='cd ~/Projects/'

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# utils
alias cd='z'
alias agyd='agy --dangerously-skip-permissions'
alias lg='lazygit'
alias lzd='lazydocker'
alias cf='clear && fastfetch'

function vsc() {
    code "${@:-.}" && exit
}

if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
