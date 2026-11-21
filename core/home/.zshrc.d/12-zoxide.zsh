# ==============================================================================
# 12-zoxide.zsh - Smart directory navigation with zoxide & cd integration
# ==============================================================================

if command -v zoxide >/dev/null 2>&1; then
    export _ZO_DOCTOR=0
    eval "$(zoxide init zsh)"

    # Transparently integrate zoxide into cd:
    # 1. Existing paths (e.g. cd .., cd /tmp, cd relative/dir) use fast builtin cd directly
    # 2. Non-path keywords (e.g. cd myrepo) jump via zoxide
    cd() {
        if [ "$#" -eq 0 ]; then
            builtin cd
        elif [ "$#" -eq 1 ] && [ "$1" = '-' ]; then
            builtin cd -
        elif [ "$#" -eq 1 ] && [ -d "$1" ]; then
            builtin cd -- "$1"
        else
            z "$@" || builtin cd "$@"
        fi
    }
    alias cdi='zi'
fi
