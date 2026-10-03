# ~/.bashrc.d/03-integrations.bash - Shell completions and third-party tools

# ------------------------------------------------------------------------------
# Programmable Completion
# ------------------------------------------------------------------------------
if [ -n "$BASH_VERSION" ] && ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# ------------------------------------------------------------------------------
# Starship Prompt
# ------------------------------------------------------------------------------
if [ -n "$BASH_VERSION" ] && command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# ------------------------------------------------------------------------------
# FZF (Fuzzy Finder)
# ------------------------------------------------------------------------------
if [ -n "$BASH_VERSION" ]; then
    [ -f "$HOME/.fzf.bash" ] && . "$HOME/.fzf.bash"
fi

# ------------------------------------------------------------------------------
# Zoxide (Smart directory jumping)
# ------------------------------------------------------------------------------
if command -v zoxide >/dev/null 2>&1; then
    export _ZO_DOCTOR=0
    if [ -n "$ZSH_VERSION" ]; then
        eval "$(zoxide init zsh --cmd cd)"
    else
        eval "$(zoxide init bash --cmd cd)"
    fi
    alias z='cd'
    alias zi='cdi'
fi
