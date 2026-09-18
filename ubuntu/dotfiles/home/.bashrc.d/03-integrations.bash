# ~/.bashrc.d/03-integrations.bash - Shell completions and third-party tools

# ------------------------------------------------------------------------------
# Programmable Completion
# ------------------------------------------------------------------------------
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# ------------------------------------------------------------------------------
# Starship Prompt
# ------------------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# ------------------------------------------------------------------------------
# FZF (Fuzzy Finder)
# ------------------------------------------------------------------------------
[ -f "$HOME/.fzf.bash" ] && . "$HOME/.fzf.bash"

# ------------------------------------------------------------------------------
# Zoxide (Smart directory jumping)
# ------------------------------------------------------------------------------
if command -v zoxide >/dev/null 2>&1; then
    export _ZO_DOCTOR=0
    eval "$(zoxide init bash --cmd cd)"
    alias z='cd'
    alias zi='cdi'
fi
