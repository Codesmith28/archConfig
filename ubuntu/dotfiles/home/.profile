# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1) if ~/.bash_profile or ~/.bash_login exists.

PROFILE_SOURCED=1
_SOURCING_PROFILE=1

# ------------------------------------------------------------------------------
# 1. Shell Environment & Default Programs
# ------------------------------------------------------------------------------
export EDITOR='nvim'
export VISUAL='nvim'

# ------------------------------------------------------------------------------
# 2. PATH & Library Path Configuration (deduplicated)
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
_path_prepend "/opt/nvim-linux-x86_64/bin"

# NVIDIA CUDA Toolkit
_path_prepend "/usr/local/cuda-12.6/bin"
_ldpath_prepend "/usr/local/cuda-12.6/lib64"
case ":$PATH:" in
    *":/usr/local/cuda-12.6/bin:"*) ;;
    *) export PATH="/usr/local/cuda-12.6/bin${PATH:+:${PATH}}" ;;
esac
case ":$LD_LIBRARY_PATH:" in
    *":/usr/local/cuda-12.6/lib64:"*) ;;
    *) export LD_LIBRARY_PATH="/usr/local/cuda-12.6/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" ;;
esac

export PATH
export LD_LIBRARY_PATH

unset -f _path_prepend _ldpath_prepend

# ------------------------------------------------------------------------------
# 3. Language & Tool Environments
# ------------------------------------------------------------------------------
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ------------------------------------------------------------------------------
# 4. Source ~/.bashrc for interactive Bash login shells
# ------------------------------------------------------------------------------
if [ -n "$BASH_VERSION" ] && [ -z "$_SOURCING_BASHRC" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

unset _SOURCING_PROFILE
