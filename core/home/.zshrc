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

# ---------- Plugin Settings (configured before plugin sourcing) ----------
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# ---------- Antidote Plugin Manager & Static Bundle Loading ----------
_antidote_dir=""
for _dir in \
    "${ARCHCONFIG_ANTIDOTE_DIR:-}" \
    "${ZDOTDIR:-$HOME}/.antidote" \
    "$HOME/.antidote" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/antidote" \
    /usr/share/zsh-antidote \
    /usr/share/antidote \
    /opt/homebrew/share/antidote \
    /usr/local/share/antidote; do
    if [ -n "$_dir" ] && [ -f "$_dir/antidote.zsh" ]; then
        _antidote_dir="$_dir"
        break
    fi
done

# Auto-bootstrap Antidote via git or curl if missing (cross-distro user-space installer)
if [ -z "$_antidote_dir" ]; then
    _antidote_dir="${ZDOTDIR:-$HOME}/.antidote"
    if command -v git >/dev/null 2>&1; then
        git clone --quiet --depth=1 https://github.com/mattmc3/antidote.git "$_antidote_dir" 2>/dev/null
    elif command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
        mkdir -p "$_antidote_dir" 2>/dev/null
        curl -fsSL https://github.com/mattmc3/antidote/archive/refs/heads/main.tar.gz 2>/dev/null | tar -xz --strip-components=1 -C "$_antidote_dir" 2>/dev/null
    fi
    [ -f "$_antidote_dir/antidote.zsh" ] || _antidote_dir=""
fi

_plugins_txt="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.txt"
_plugins_zsh="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.zsh"
[ -f "$_plugins_txt" ] || _plugins_txt="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
[ -f "$_plugins_txt" ] || _plugins_txt="${ARCHCONFIG_DIR:-$HOME/archConfig}/core/config/zsh/plugins.txt"
[ -f "$_plugins_zsh" ] || _plugins_zsh="${ZDOTDIR:-$HOME}/.zsh_plugins.zsh"

# Ensure plugins.txt exists with default cross-distro plugin suite
if [ ! -f "$_plugins_txt" ]; then
    _plugins_txt="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.txt"
    mkdir -p "${_plugins_txt:h}" 2>/dev/null
    cat <<'EOF' >| "$_plugins_txt" 2>/dev/null
zsh-users/zsh-completions
zsh-users/zsh-autosuggestions
zsh-users/zsh-history-substring-search
zsh-users/zsh-syntax-highlighting
EOF
fi

if [ -n "$_antidote_dir" ] && [ -f "$_plugins_txt" ]; then
    source "$_antidote_dir/antidote.zsh"
    # Fast path: if static compiled bundle exists and is newer than plugins.txt, source it directly;
    # otherwise, generate/update bundle and source it.
    if [ -f "$_plugins_zsh" ] && [ "$_plugins_zsh" -nt "$_plugins_txt" ]; then
        source "$_plugins_zsh"
    else
        mkdir -p "${_plugins_zsh:h}" 2>/dev/null
        antidote bundle < "$_plugins_txt" >| "$_plugins_zsh" 2>/dev/null
        [ -s "$_plugins_zsh" ] && source "$_plugins_zsh" || antidote load "$_plugins_txt"
    fi
elif [ -f "$_plugins_zsh" ]; then
    source "$_plugins_zsh"
fi
unset _antidote_dir _plugins_txt _plugins_zsh

# Helper to auto-download and source a standalone plugin via curl/tar if Antidote or bundle is unavailable
_bootstrap_plugin_curl() {
    local name="$1" repo="$2" entry_script="$3"
    local dest="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/$name"
    if [ ! -f "$dest/$entry_script" ] && command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
        mkdir -p "$dest" 2>/dev/null
        curl -fsSL "https://github.com/$repo/archive/refs/heads/master.tar.gz" 2>/dev/null | tar -xz --strip-components=1 -C "$dest" 2>/dev/null
    fi
    [ -f "$dest/$entry_script" ] && source "$dest/$entry_script"
}

# ---------- Fallback Multi-Distro Plugin Resolution ----------
# History Substring Search (Arch, Fedora, Debian/Ubuntu, macOS Homebrew, OMZ, or curl fallback)
if (( ! ${+widgets[history-substring-search-up]} )); then
    for _hist_search in \
        /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh \
        /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh \
        /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh \
        /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh \
        "${XDG_CACHE_HOME:-$HOME/.cache}"/antidote/**/zsh-history-substring-search.zsh(N) \
        "${XDG_DATA_HOME:-$HOME/.local/share}"/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh \
        "$HOME/.oh-my-zsh/plugins/history-substring-search/history-substring-search.plugin.zsh"; do
        if [ -f "$_hist_search" ]; then
            source "$_hist_search"
            break
        fi
    done
    unset _hist_search
    if (( ! ${+widgets[history-substring-search-up]} )); then
        _bootstrap_plugin_curl "zsh-history-substring-search" "zsh-users/zsh-history-substring-search" "zsh-history-substring-search.zsh"
    fi
fi

# Autosuggestions fallback
if ! typeset -f _zsh_autosuggest_bind_widgets >/dev/null 2>&1; then
    for _autosuggest in \
        /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        "${XDG_CACHE_HOME:-$HOME/.cache}"/antidote/**/zsh-autosuggestions.zsh(N) \
        "${XDG_DATA_HOME:-$HOME/.local/share}"/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
        if [ -f "$_autosuggest" ]; then
            source "$_autosuggest"
            break
        fi
    done
    unset _autosuggest
    if ! typeset -f _zsh_autosuggest_bind_widgets >/dev/null 2>&1; then
        _bootstrap_plugin_curl "zsh-autosuggestions" "zsh-users/zsh-autosuggestions" "zsh-autosuggestions.zsh"
    fi
fi

# Syntax Highlighting fallback
if ! typeset -f _zsh_highlight >/dev/null 2>&1; then
    for _syntax in \
        /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        "${XDG_CACHE_HOME:-$HOME/.cache}"/antidote/**/zsh-syntax-highlighting.zsh(N) \
        "${XDG_DATA_HOME:-$HOME/.local/share}"/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
        if [ -f "$_syntax" ]; then
            source "$_syntax"
            break
        fi
    done
    unset _syntax
    if ! typeset -f _zsh_highlight >/dev/null 2>&1; then
        _bootstrap_plugin_curl "zsh-syntax-highlighting" "zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting.zsh"
    fi
fi
unset -f _bootstrap_plugin_curl

# ---------- Plugin Settings & Keybindings ----------
# Use emacs keybindings by default (prevents EDITOR=nvim/vi from forcing viins mode)
bindkey -e

# Fish-like autosuggestions accept keybinding (only if widget is available)
if (( ${+widgets[autosuggest-accept]} )); then
    bindkey '^f' autosuggest-accept 2>/dev/null || true
fi

# History substring search keybindings (Up / Down arrow keys)
if (( ${+widgets[history-substring-search-up]} )) && (( ${+widgets[history-substring-search-down]} )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OA' history-substring-search-up
    bindkey '^[OB' history-substring-search-down
    [ -n "${terminfo[kcuu1]:-}" ] && bindkey "$terminfo[kcuu1]" history-substring-search-up 2>/dev/null || true
    [ -n "${terminfo[kcud1]:-}" ] && bindkey "$terminfo[kcud1]" history-substring-search-down 2>/dev/null || true
    bindkey -M vicmd 'k' history-substring-search-up 2>/dev/null || true
    bindkey -M vicmd 'j' history-substring-search-down 2>/dev/null || true
else
    # Fallback to standard line / history navigation if history-substring-search is unavailable
    bindkey '^[[A' up-line-or-history
    bindkey '^[[B' down-line-or-history
    bindkey '^[OA' up-line-or-history
    bindkey '^[OB' down-line-or-history
    [ -n "${terminfo[kcuu1]:-}" ] && bindkey "$terminfo[kcuu1]" up-line-or-history 2>/dev/null || true
    [ -n "${terminfo[kcud1]:-}" ] && bindkey "$terminfo[kcud1]" down-line-or-history 2>/dev/null || true
fi

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

# ========== FZF (Fuzzy Finder) ==========
# Ensure ~/.fzf/bin is in PATH if present
[ -d "$HOME/.fzf/bin" ] && [[ ":$PATH:" != *":$HOME/.fzf/bin:"* ]] && export PATH="$HOME/.fzf/bin:$PATH"

# Auto-bootstrap fzf binary if not present
if ! command -v fzf >/dev/null 2>&1 && [ ! -x "$HOME/.fzf/bin/fzf" ]; then
    if command -v git >/dev/null 2>&1; then
        git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>/dev/null
        [ -x "$HOME/.fzf/install" ] && "$HOME/.fzf/install" --bin >/dev/null 2>&1
        [ -d "$HOME/.fzf/bin" ] && export PATH="$HOME/.fzf/bin:$PATH"
    fi
fi

if command -v fzf >/dev/null 2>&1; then
    # Enhanced search backend (fd / fdfind if available)
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

    # Sourcing completion and keybindings
    # 1. Modern fzf (0.48+) native zsh integration
    if fzf --zsh >/dev/null 2>&1; then
        eval "$(fzf --zsh)"
    # 2. Traditional ~/.fzf.zsh wrapper
    elif [ -f "$HOME/.fzf.zsh" ]; then
        source "$HOME/.fzf.zsh"
    # 3. Multi-distro package paths (Arch, Fedora, Debian/Ubuntu, macOS Homebrew, git)
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



# Ensure ~/.local/bin is available in Zsh environment
export PATH="$HOME/.local/bin:$PATH"

