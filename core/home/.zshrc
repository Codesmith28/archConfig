# ==============================================================================
# archConfig Universal Zsh Configuration
# ==============================================================================

# ---------- 1. Environment & Base PATH (Source .profile first) ----------
if [ -z "$_SOURCING_PROFILE" ] && [ -f "$HOME/.profile" ]; then
    _SOURCING_ZSHRC=1
    source "$HOME/.profile"
    unset _SOURCING_ZSHRC
fi

# ---------- 2. Command History Persistence & Hygiene ----------
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}" 2>/dev/null || true
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY          # Share history across open terminals in real time
setopt EXTENDED_HISTORY       # Record timestamps and elapsed duration
setopt HIST_IGNORE_ALL_DUPS   # Drop older duplicates
setopt HIST_REDUCE_BLANKS     # Trim extra whitespace
setopt HIST_IGNORE_SPACE      # Ignore commands starting with space
setopt HIST_VERIFY            # Verify history expansion before executing
setopt INC_APPEND_HISTORY     # Save immediately upon command execution

# Shell navigation
setopt AUTO_CD                # Type directory name to cd into it
setopt AUTO_PUSHD             # Push old directory onto stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates
setopt PUSHD_SILENT           # Don't print directory stack after pushd/popd

# ---------- 3. Plugin Settings (Configured before sourcing plugins) ----------
typeset -a ZSH_AUTOSUGGEST_STRATEGY
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# ---------- 4. Load Plugins (Antidote / Static Bundle) before compinit ----------
_antidote_dir=""
for _dir in \
    "${ARCHCONFIG_ANTIDOTE_DIR:-}" \
    "${ZDOTDIR:-$HOME}/.antidote" \
    "$HOME/.antidote" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/antidote" \
    /usr/share/zsh-antidote \
    /usr/share/antidote \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/share/antidote" \
    /usr/local/share/antidote; do
    if [ -n "$_dir" ] && [ -f "$_dir/antidote.zsh" ]; then
        _antidote_dir="$_dir"
        break
    fi
done

_plugins_txt="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.txt"
_plugins_zsh="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.zsh"
[ -f "$_plugins_txt" ] || _plugins_txt="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
[ -f "$_plugins_txt" ] || _plugins_txt="${ARCHCONFIG_DIR:-$HOME/archConfig}/core/config/zsh/plugins.txt"
[ -f "$_plugins_zsh" ] || _plugins_zsh="${ZDOTDIR:-$HOME}/.zsh_plugins.zsh"

if [ -n "$_antidote_dir" ] && [ -f "$_plugins_txt" ]; then
    source "$_antidote_dir/antidote.zsh"
    if [ -f "$_plugins_zsh" ] && [ "$_plugins_zsh" -nt "$_plugins_txt" ]; then
        source "$_plugins_zsh"
    else
        mkdir -p "${_plugins_zsh:h}" 2>/dev/null
        antidote bundle < "$_plugins_txt" >| "$_plugins_zsh" 2>/dev/null
        [ -s "$_plugins_zsh" ] && source "$_plugins_zsh" || antidote load "$_plugins_txt"
    fi
elif [ -f "$_plugins_zsh" ]; then
    source "$_plugins_zsh"
else
    # Fallback: check distro-packaged plugins without network overhead
    for _plugin_script in \
        /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
        /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
        [ -f "$_plugin_script" ] && source "$_plugin_script" 2>/dev/null
    done
fi
unset _antidote_dir _plugins_txt _plugins_zsh _plugin_script

# ---------- 5. Completion System (Indexed after fpath additions) ----------
autoload -Uz compinit
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"
mkdir -p "${ZSH_COMPDUMP:h}" 2>/dev/null

setopt COMPLETE_IN_WORD    # Complete from both ends of a word
setopt ALWAYS_TO_END       # Move cursor to end of word after completion
setopt AUTO_MENU           # Show completion menu on successive tab press
setopt AUTO_LIST           # Automatically list choices on ambiguous completion
setopt NO_LIST_BEEP        # Don't beep on ambiguous completion

zstyle ':completion:*' matcher-list '' \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*'

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*' group-name ''

compinit -d "$ZSH_COMPDUMP" -C

# ---------- 6. Terminal Keybindings & Modes ----------
bindkey -e

typeset -A key
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"

[[ -n "${key[Home]}" ]]      && bindkey -- "${key[Home]}"      beginning-of-line
[[ -n "${key[End]}" ]]       && bindkey -- "${key[End]}"       end-of-line
[[ -n "${key[Insert]}" ]]    && bindkey -- "${key[Insert]}"    overwrite-mode
[[ -n "${key[Delete]}" ]]    && bindkey -- "${key[Delete]}"    delete-char
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}" reverse-menu-complete

# History substring search if loaded
if (( ${+widgets[history-substring-search-up]} )); then
    [[ -n "${key[Up]}" ]]   && bindkey -- "${key[Up]}"   history-substring-search-up
    [[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" history-substring-search-down
    bindkey -M emacs '^P' history-substring-search-up
    bindkey -M emacs '^N' history-substring-search-down
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
else
    [[ -n "${key[Up]}" ]]   && bindkey -- "${key[Up]}"   up-line-or-history
    [[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" down-line-or-history
fi

# Multi-terminal key sequence mappings for navigation
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^W' backward-kill-word
bindkey '^U' backward-kill-line
bindkey '^K' kill-line
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Word navigation across terminals (Ghostty, Alacritty, iTerm2, Kitty, xterm)
for _key in '^[b' '^[B' '^[[1;3D' '^[[1;5D' '^[[1;4D' '^[[1;6D' '^[[1;9D' '^[[1;10D' '^[^[[D' '^[^[OD' '^[[5D' '^[[3D'; do
    bindkey -M emacs "$_key" backward-word 2>/dev/null || true
    bindkey -M viins "$_key" backward-word 2>/dev/null || true
    bindkey -M vicmd "$_key" backward-word 2>/dev/null || true
done
for _key in '^[f' '^[F' '^[[1;3C' '^[[1;5C' '^[[1;4C' '^[[1;6C' '^[[1;9C' '^[[1;10C' '^[^[[C' '^[^[OC' '^[[5C' '^[[3C'; do
    bindkey -M emacs "$_key" forward-word 2>/dev/null || true
    bindkey -M viins "$_key" forward-word 2>/dev/null || true
    bindkey -M vicmd "$_key" forward-word 2>/dev/null || true
done
unset _key

# ---------- 7. Prompt (Starship) ----------
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# Deferred plugins utility
[ -f "$HOME/.zsh-defer/zsh-defer.plugin.zsh" ] && source "$HOME/.zsh-defer/zsh-defer.plugin.zsh" 2>/dev/null

# ---------- 8. FZF (Fuzzy Finder) ----------
[ -d "$HOME/.fzf/bin" ] && [[ ":$PATH:" != *":$HOME/.fzf/bin:"* ]] && export PATH="$HOME/.fzf/bin:$PATH"

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

# ---------- 9. Developer Runtimes & Paths ----------
# PNPM
if [ -d "$HOME/.local/share/pnpm" ]; then
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
fi

# Lazy-load NVM
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

# Pyenv
if [ -d "$HOME/.pyenv" ] || command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    [ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"
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
    [ -d "$_gopath/bin" ] && export PATH="$PATH:$_gopath/bin"
    unset _gopath
fi

# Rust / Cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# ---------- 10. Modular Aliases & Functions ----------
if [ -d "$HOME/.bashrc.d" ]; then
    for rc in "$HOME/.bashrc.d"/*.bash; do
        [ -r "$rc" ] && source "$rc"
    done
    unset rc
fi

# Local workstation overrides
[ -f "$HOME/.config/work/work.sh" ] && source "$HOME/.config/work/work.sh"
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Ensure ~/.local/bin is present in PATH
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"
