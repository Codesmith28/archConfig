export EDITOR=nvim

# Point CC and CXX to Homebrew's generic, unversioned GCC links
export CC=gcc
export CXX=g++

alias cd='z'
alias c='clear'
alias e='exit'

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

alias ff='fastfetch'
alias cf='c && fastfetch'

alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -a --icons'
alias lla='eza -al --icons'
lt() {
    local level=${1:-1}
    eza -a --tree --level="$level" --icons
}

alias confp='$EDITOR ~/.profile'
alias confb='$EDITOR ~/.bashrc'
alias confz='$EDITOR ~/.zshrc'
alias confn='$EDITOR ~/.config/nvim'
alias confg='$EDITOR ~/.config/ghostty/config'

alias source_z='source ~/.zshrc'
alias source_venv='source venv/bin/activate'
alias ssh-work='ssh -i ~/.ssh/id_work'

alias lg='lazygit'
alias gwt='git worktree'
alias gcl-work='git -c core.sshCommand="ssh -i ~/.ssh/id_work" clone'
alias gcl-personal='git -c core.sshCommand="ssh -i ~/.ssh/id_personal" clone'

alias fzf="fzf --style full --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"
alias ivm='$EDITOR $(fzf -m --preview="bat --color=always --style=header,grid --line-range :500 {}")'

runcpp() {
    # filename=$(echo $1 | cut -f 1 -d '.')
    # clang++ "$1" -o $filename && ./$filename
    g++-16 -std=c++23 "$1" -o run && "./run"
    rm -f run
}
runcc() {
    clang "$1" -o run && "./run"
    rm -f run
}

alias agyd='agy --dangerously-skip-permissions'

export PATH="/Users/codesmith28/.local/bin:$PATH"
