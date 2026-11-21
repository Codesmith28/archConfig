# ==============================================================================
# 06-fzf.zsh - Fuzzy Finder (FZF) Integration
# ==============================================================================

if command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
    elif command -v fdfind >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fdfind --type d --hidden --exclude .git'
    fi

    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'

    if fzf --zsh >/dev/null 2>&1; then
        eval "$(fzf --zsh)"
    elif [ -f "$HOME/.fzf.zsh" ]; then
        source "$HOME/.fzf.zsh"
    else
        for _fzf_dir in \
            /usr/share/fzf \
            /usr/share/fzf/shell \
            /usr/share/doc/fzf/examples \
            "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell" \
            /usr/local/opt/fzf/shell \
            "$HOME/.fzf/shell"; do
            if [ -f "$_fzf_dir/key-bindings.zsh" ]; then
                [ -f "$_fzf_dir/completion.zsh" ] && source "$_fzf_dir/completion.zsh" 2>/dev/null
                source "$_fzf_dir/key-bindings.zsh" 2>/dev/null
                break
            fi
        done
        unset _fzf_dir
    fi
elif [ -f "$HOME/.fzf.zsh" ]; then
    source "$HOME/.fzf.zsh"
fi
