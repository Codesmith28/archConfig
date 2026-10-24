# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1) if ~/.bash_profile or ~/.bash_login exists.

PROFILE_SOURCED=1
_SOURCING_PROFILE=1

# ------------------------------------------------------------------------------
# 1. PATH & Library Path Configuration (deduplicated)
# ------------------------------------------------------------------------------
_path_prepend() {
    if [ -d "$1" ]; then
        case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
        esac
    fi
}

_ldpath_prepend() {
    if [ -d "$1" ]; then
        case ":$LD_LIBRARY_PATH:" in
        *":$1:"*) ;;
        *) LD_LIBRARY_PATH="$1${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
        esac
    fi
}

# Standard user binary directories
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/.fzf/bin"
_path_prepend "/opt/nvim-linux-x86_64/bin"
_path_prepend "/opt/homebrew/bin"
_path_prepend "/opt/homebrew/sbin"

unset -f _path_prepend _ldpath_prepend

# ------------------------------------------------------------------------------
# 2. Shell Environment & Default Programs
# ------------------------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
    export EDITOR='nvim'
else
    export EDITOR='vi'
fi

# ------------------------------------------------------------------------------
# 3. Language & Tool Environments
# ------------------------------------------------------------------------------
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && . "$HOME/.sdkman/bin/sdkman-init.sh"
[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"

# ------------------------------------------------------------------------------
# 4. Work & Private Environment / Shortcuts (Import if present)
# ------------------------------------------------------------------------------
if [ -f "$HOME/.config/work/work.sh" ]; then
    . "$HOME/.config/work/work.sh"
fi

# ------------------------------------------------------------------------------
# 5. Centralized Shell Reload Helper & Interactive Shell Handoff
# ------------------------------------------------------------------------------
unalias source_p 2>/dev/null || true
source_p() {
    if [ -n "$ZSH_VERSION" ]; then
        source "$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        . "$HOME/.bashrc"
    else
        . "$HOME/.profile"
    fi
}
alias sourcep='source_p' 2>/dev/null || true
alias src='source_p' 2>/dev/null || true

# If ~/.profile is sourced directly in an interactive shell (e.g. manual reload),
# hand off to the active shell's interactive runtime while preventing circular recursion.
if [ -n "$BASH_VERSION" ] && [ -z "$_SOURCING_BASHRC" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        _SOURCING_PROFILE=1
        . "$HOME/.bashrc"
        unset _SOURCING_PROFILE
    fi
elif [ -n "$ZSH_VERSION" ] && [ -z "$_SOURCING_ZSHRC" ]; then
    if [ -f "$HOME/.zshrc" ]; then
        _SOURCING_PROFILE=1
        source "$HOME/.zshrc"
        unset _SOURCING_PROFILE
    fi
fi

unset _SOURCING_PROFILE



# Ensure ~/.local/bin is available in POSIX environment
export PATH="$HOME/.local/bin:$PATH"
