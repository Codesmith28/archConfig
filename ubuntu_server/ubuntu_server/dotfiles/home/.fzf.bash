# Setup fzf
# ---------
if [[ ! "$PATH" == *~/.fzf/bin* ]]; then
    PATH="${PATH:+${PATH}:}~/.fzf/bin"
fi

eval "$(fzf --bash)"
