# ==============================================================================
# 07-runtimes.zsh - Developer Runtimes (PNPM, NVM, Pyenv, Go, Bun)
# ==============================================================================

# PNPM
if [ -d "$HOME/.local/share/pnpm" ]; then
    export PNPM_HOME="$HOME/.local/share/pnpm"
    case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
fi

# Lazy-load NVM
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    nvm() {
        unset -f nvm
        source "$NVM_DIR/nvm.sh" --no-use
        nvm "$@"
    }
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    if command -v zsh-defer >/dev/null 2>&1; then
        zsh-defer source "$NVM_DIR/bash_completion"
    else
        source "$NVM_DIR/bash_completion"
    fi
fi

# Pyenv
if [ -d "$HOME/.pyenv" ] || command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    [ -d "$PYENV_ROOT/bin" ] && case ":$PATH:" in *":$PYENV_ROOT/bin:"*) ;; *) export PATH="$PYENV_ROOT/bin:$PATH" ;; esac
    if command -v pyenv >/dev/null 2>&1; then
        if command -v zsh-defer >/dev/null 2>&1; then
            zsh-defer eval "$(pyenv init --path)"
            zsh-defer eval "$(pyenv init -)"
        else
            eval "$(pyenv init --path)"
            eval "$(pyenv init -)"
        fi
    fi
fi

# Go
if command -v go >/dev/null 2>&1; then
    _gopath="${GOPATH:-$HOME/go}"
    if [ -d "$_gopath/bin" ]; then
        case ":$PATH:" in
            *":$_gopath/bin:"*) ;;
            *) export PATH="$PATH:$_gopath/bin" ;;
        esac
    fi
    unset _gopath
fi

# Bun JavaScript runtime
if [ -d "$HOME/.bun" ]; then
    export BUN_INSTALL="$HOME/.bun"
    if [ -d "$BUN_INSTALL/bin" ]; then
        case ":$PATH:" in
            *":$BUN_INSTALL/bin:"*) ;;
            *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
        esac
    fi
    if [ -s "$BUN_INSTALL/_bun" ]; then
        if command -v zsh-defer >/dev/null 2>&1; then
            zsh-defer source "$BUN_INSTALL/_bun"
        else
            source "$BUN_INSTALL/_bun"
        fi
    fi
fi
