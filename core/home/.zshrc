# ==============================================================================
# archConfig Universal Zsh Configuration
# ==============================================================================

# Completion caching & initialization
autoload -Uz compinit
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"
mkdir -p "$(dirname "$ZSH_COMPDUMP")"
zstyle ':completion:*' rehash true
compinit -d "$ZSH_COMPDUMP" -C

# ---------- Antidote Plugin Manager ----------
if [ -f "$HOME/.antidote/antidote.zsh" ]; then
    source "$HOME/.antidote/antidote.zsh"
    if [ -f "$HOME/.config/zsh/plugins.txt" ]; then
        antidote load "$HOME/.config/zsh/plugins.txt"
    fi
fi

# ---------- Plugin Settings & Keybindings ----------
# Fish-like autosuggestions settings
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
bindkey '^f' autosuggest-accept 2>/dev/null || true

# History substring search keybindings (Up / Down arrow keys)
bindkey '^[[A' history-substring-search-up 2>/dev/null || true
bindkey '^[[B' history-substring-search-down 2>/dev/null || true

# ============ Basic config ============
[[ -e ~/.profile ]] && source ~/.profile
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ========== Deferred plugins ==========
[ -f "$HOME/.zsh-defer/zsh-defer.plugin.zsh" ] && source "$HOME/.zsh-defer/zsh-defer.plugin.zsh" 2>/dev/null

# These are heavy → defer them
if [ -f ~/.fzf.zsh ]; then
    command -v zsh-defer >/dev/null 2>&1 && zsh-defer source ~/.fzf.zsh || source ~/.fzf.zsh
fi


# ========== PNPM ==========
if [ -d "$HOME/.local/share/pnpm" ]; then
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
fi


# ========== Lazy-load NVM ==========
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    nvm() {
        unset -f nvm
        source "$NVM_DIR/nvm.sh" --no-use
        nvm "$@"
    }
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    command -v zsh-defer >/dev/null 2>&1 && zsh-defer source "$NVM_DIR/bash_completion" || source "$NVM_DIR/bash_completion"
fi


# Default Node.js version in PATH (only run if variable set)
if [[ -n "$DEFAULT_NODE_VER" && -d "$NVM_DIR/versions/node" ]]; then
  DEFAULT_NODE_VER_PATH="$(find "$NVM_DIR/versions/node" -maxdepth 1 -name "v${DEFAULT_NODE_VER#v}*" | sort -rV | head -n 1)"
  [[ -n "$DEFAULT_NODE_VER_PATH" ]] && export PATH="$DEFAULT_NODE_VER_PATH/bin:$PATH"
fi


# ========== Bun ==========
if [ -d "$HOME/.bun" ]; then
    export BUN_INSTALL="$HOME/.bun"
    [ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"
    if [ -s "$HOME/.bun/_bun" ]; then
        command -v zsh-defer >/dev/null 2>&1 && zsh-defer source "$HOME/.bun/_bun" || source "$HOME/.bun/_bun"
    fi
fi


# ========== Pyenv ==========
if [ -d "$HOME/.pyenv" ] || command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    [ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv >/dev/null 2>&1; then
        if command -v zsh-defer >/dev/null 2>&1; then
            zsh-defer eval "$(pyenv init --path)"
            zsh-defer eval "$(pyenv init -)"
            if command -v pyenv-virtualenv-init >/dev/null 2>&1 || [ -d "${PYENV_ROOT:-$HOME/.pyenv}/plugins/pyenv-virtualenv" ]; then
                zsh-defer eval "$(pyenv virtualenv-init -)"
            fi
        else
            eval "$(pyenv init --path)"
            eval "$(pyenv init -)"
            if command -v pyenv-virtualenv-init >/dev/null 2>&1 || [ -d "${PYENV_ROOT:-$HOME/.pyenv}/plugins/pyenv-virtualenv" ]; then
                eval "$(pyenv virtualenv-init -)"
            fi
        fi
    fi
fi


# ========== Go Path ==========
if command -v go >/dev/null 2>&1; then
    _gopath="$(go env GOPATH 2>/dev/null || true)"
    [ -n "$_gopath" ] && export PATH="$PATH:$_gopath/bin"
    unset _gopath
fi

# ========== Rust / Cargo ==========
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"


# ========== Modular Aliases, Functions, & Compiler Detection ==========
if [ -d "$HOME/.bashrc.d" ]; then
    for rc in "$HOME/.bashrc.d"/*.bash; do
        [ -r "$rc" ] && source "$rc" >/dev/null
    done
    unset rc
fi

