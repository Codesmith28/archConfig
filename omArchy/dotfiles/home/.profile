# editor
export EDITOR='nvim'

# editing configs:
alias confb='$EDITOR ~/.bashrc'
alias confp='$EDITOR ~/.profile'
alias confn='$EDITOR ~/.config/nvim/'
alias confg='$EDITOR ~/.config/ghostty/config'

# sourcing
alias sourceb='source ~/.bash_profile'
alias source_venv='source ./venv/bin/activate'

# shell:
alias c='clear'
alias e='exit'

# navigation
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -a --icons'
alias lla='eza -al --icons'
alias pj='cd ~/Projects/'

function lt() {
    local level=${1:-1}
    eza -a --tree --level="$level" --icons
}

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# utils
alias agyd='agy --dangerously-skip-permissions'
alias lg='lazygit'
alias lzd='lazydocker'
alias cf='clear && fastfetch'

function vsc() {
    code "${@:-.}" && exit
}

. "$HOME/.local/share/../bin/env"
. "$HOME/.cargo/env"
