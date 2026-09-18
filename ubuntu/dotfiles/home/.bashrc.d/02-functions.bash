# ~/.bashrc.d/02-functions.bash - Shell functions & helper utilities

# ------------------------------------------------------------------------------
# Directory tree listing via eza
# ------------------------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
    function lt() {
        local level=${1:-1}
        eza -a --tree --level="$level" --icons
    }
fi

# ------------------------------------------------------------------------------
# Yazi wrapper: cd to directory on exit
# ------------------------------------------------------------------------------
function y() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if [ -f "$tmp" ]; then
        local cwd
        cwd="$(command cat -- "$tmp")"
        if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
    fi
}

# ------------------------------------------------------------------------------
# VSCode shortcut: open project and close terminal
# ------------------------------------------------------------------------------
function vsc() {
    code "${@:-.}" && exit
}
