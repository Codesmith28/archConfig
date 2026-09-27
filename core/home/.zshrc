# ========== Oh My Zsh config ==========
# export ZSH="$HOME/.oh-my-zsh"
# DISABLE_AUTO_UPDATE="true"
# DISABLE_UPDATE_PROMPT="true"
# ZSH_DISABLE_COMPFIX=true
#
# plugins=(git zsh-autosuggestions) # remove zsh-syntax-highlighting here; load it last
# source $ZSH/oh-my-zsh.sh
# Use cached compinit for fast startup

autoload -Uz compinit
ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump"
zstyle ':completion:*' rehash true
compinit -C

# ---------- Antidote ----------
if [ -f "$HOME/.antidote/antidote.zsh" ]; then
    source "$HOME/.antidote/antidote.zsh"
    [ -f "$HOME/.config/zsh/plugins.txt" ] && antidote load "$HOME/.config/zsh/plugins.txt"
fi

# ============ Basic config ============
[[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile'
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ========== Deferred plugins ==========
[ -f "$HOME/.zsh-defer/zsh-defer.plugin.zsh" ] && source "$HOME/.zsh-defer/zsh-defer.plugin.zsh" 2>/dev/null

# These are heavy → defer them
if [ -f ~/.fzf.zsh ]; then
    command -v zsh-defer >/dev/null 2>&1 && zsh-defer source ~/.fzf.zsh || source ~/.fzf.zsh
fi

# zsh-syntax-highlighting must load last → defer!
if [ -n "${ZSH:-}" ] && [ -f "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    command -v zsh-defer >/dev/null 2>&1 && zsh-defer source "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" || source "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
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
            zsh-defer eval "$(pyenv virtualenv-init -)"
        else
            eval "$(pyenv init --path)"
            eval "$(pyenv init -)"
            eval "$(pyenv virtualenv-init -)"
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
        [ -r "$rc" ] && source "$rc"
    done
    unset rc
fi

