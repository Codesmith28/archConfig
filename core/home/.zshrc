# ==============================================================================
# archConfig Universal Zsh Configuration
# ==============================================================================

# ---------- Completion System & Intelligent Matching ----------
autoload -Uz compinit
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"
mkdir -p "$(dirname "$ZSH_COMPDUMP")"

# Completion options
setopt COMPLETE_IN_WORD    # Complete from both ends of a word if cursor is in the middle
setopt ALWAYS_TO_END       # Move cursor to end of word after completion
setopt AUTO_MENU           # Show completion menu on successive tab press
setopt AUTO_LIST           # Automatically list choices on ambiguous completion
setopt NO_LIST_BEEP        # Don't beep on ambiguous completion

# Intelligent matching specifications:
# 1. Exact match first ('')
# 2. Case-insensitive prefix match (m:{a-zA-Z}={A-Za-z})
# 3. Partial-word match separated by delimiters (e.g. c_m -> cust_malaysia)
# 4. Substring & case-insensitive match (e.g. malaysia -> cust_malaysia)
zstyle ':completion:*' matcher-list '' \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*'

# Interactive menu selection (arrow-key navigation in completion lists)
zstyle ':completion:*' menu select

# Colorize completion list using LS_COLORS
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Auto-rehash binaries and clean up slashes
zstyle ':completion:*' rehash true
zstyle ':completion:*' squeeze-slashes true

# Grouping and descriptions for completions
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*' group-name ''

compinit -d "$ZSH_COMPDUMP" -C

# ---------- Antidote Plugin Manager ----------
if [ -f "$HOME/.antidote/antidote.zsh" ]; then
    source "$HOME/.antidote/antidote.zsh"
    if [ -f "$HOME/.config/zsh/plugins.txt" ]; then
        antidote load "$HOME/.config/zsh/plugins.txt"
    fi
fi

# ---------- Plugin Settings & Keybindings ----------
# Use emacs keybindings by default (prevents EDITOR=nvim/vi from forcing viins mode)
bindkey -e

# Fish-like autosuggestions settings
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
bindkey '^f' autosuggest-accept 2>/dev/null || true

# History substring search keybindings (Up / Down arrow keys)
bindkey '^[[A' history-substring-search-up 2>/dev/null || true
bindkey '^[[B' history-substring-search-down 2>/dev/null || true

# Completion menu navigation (Shift-Tab cycles backward)
bindkey '^[[Z' reverse-menu-complete 2>/dev/null || true

# Word boundary customization: exclude '/' so backward-kill-word stops at path components
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Word deletion keybindings (Alt + Backspace / Option + Delete)
bindkey '^[^?' backward-kill-word
bindkey '^[^H' backward-kill-word
bindkey '^W' backward-kill-word
bindkey '^U' backward-kill-line

# Word navigation (Alt+Left/Right, Option+Left/Right, Ctrl+Left/Right, Esc+b/f)
# Standard Emacs / Readline sequences (Terminal.app with Option as Meta, Ghostty, iTerm2)
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[B' backward-word
bindkey '^[F' forward-word

# xterm modifier sequences (1;3 = Alt, 1;5 = Ctrl, 1;4 = Alt+Shift, 1;6 = Ctrl+Shift, 1;9 = Cmd/Opt)
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;4D' backward-word
bindkey '^[[1;4C' forward-word
bindkey '^[[1;6D' backward-word
bindkey '^[[1;6C' forward-word
bindkey '^[[1;9D' backward-word
bindkey '^[[1;9C' forward-word
bindkey '^[[1;10D' backward-word
bindkey '^[[1;10C' forward-word

# Esc-prefixed CSI / SS3 arrow sequences (when terminal sends ESC prefix before arrow keys)
bindkey '^[^[[D' backward-word
bindkey '^[^[[C' forward-word
bindkey '^[^[OD' backward-word
bindkey '^[^[OC' forward-word

# rxvt, urxvt, and legacy Terminal.app sequences
bindkey '^[[5D' backward-word
bindkey '^[[5C' forward-word
bindkey '^[[3D' backward-word
bindkey '^[[3C' forward-word

# Line editing navigation (Home / End / Delete)
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[7~' beginning-of-line
bindkey '^[[8~' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[3;3~' kill-word
bindkey '^[[3;5~' kill-word

# Fallback bindings for viins & vicmd modes (in case vi mode is explicitly activated)
for _key in '^[^?' '^[^H' '^W'; do
    bindkey -M viins "$_key" backward-kill-word 2>/dev/null || true
done
for _key in '^[b' '^[B' '^[[1;3D' '^[[1;5D' '^[[1;4D' '^[[1;6D' '^[[1;9D' '^[[1;10D' '^[^[[D' '^[^[OD' '^[[5D' '^[[3D'; do
    bindkey -M viins "$_key" backward-word 2>/dev/null || true
    bindkey -M vicmd "$_key" backward-word 2>/dev/null || true
done
for _key in '^[f' '^[F' '^[[1;3C' '^[[1;5C' '^[[1;4C' '^[[1;6C' '^[[1;9C' '^[[1;10C' '^[^[[C' '^[^[OC' '^[[5C' '^[[3C'; do
    bindkey -M viins "$_key" forward-word 2>/dev/null || true
    bindkey -M vicmd "$_key" forward-word 2>/dev/null || true
done
unset _key

# ============ Basic config ============
if [ -z "$_SOURCING_PROFILE" ] && [ -f "$HOME/.profile" ]; then
    _SOURCING_ZSHRC=1
    source "$HOME/.profile"
    unset _SOURCING_ZSHRC
fi
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
        [ -r "$rc" ] && source "$rc"
    done
    unset rc
fi

# ========== Work & Private Configurations (Import if present) ==========
if [ -f "$HOME/.config/work/work.sh" ]; then
    source "$HOME/.config/work/work.sh"
fi
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

