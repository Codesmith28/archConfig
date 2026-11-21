# ==============================================================================
# 02-plugins.zsh - Antidote plugin manager & static bundle loader
# ==============================================================================

# Plugin configurations (configured before sourcing plugins)
typeset -a ZSH_AUTOSUGGEST_STRATEGY
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# Deferred plugins utility (romkatv/zsh-defer)
_defer_dir="${ARCHCONFIG_ZSH_DEFER_DIR:-$HOME/.zsh-defer}"
[ -f "$_defer_dir/zsh-defer.plugin.zsh" ] && source "$_defer_dir/zsh-defer.plugin.zsh" 2>/dev/null
unset _defer_dir

# ------------------------------------------------------------------------------
# Locate or Bootstrap Antidote Plugin Manager
# ------------------------------------------------------------------------------
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

# Zero-friction auto-bootstrapping: clone or download if Antidote is missing
if [ -z "$_antidote_dir" ] || [ ! -f "$_antidote_dir/antidote.zsh" ]; then
    _antidote_dir="${ARCHCONFIG_ANTIDOTE_DIR:-${ZDOTDIR:-$HOME}/.antidote}"
    if [ ! -f "$_antidote_dir/antidote.zsh" ]; then
        if command -v git >/dev/null 2>&1; then
            git clone --depth=1 https://github.com/mattmc3/antidote.git "$_antidote_dir" 2>/dev/null
        fi
        if [ ! -f "$_antidote_dir/antidote.zsh" ] && command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
            mkdir -p "$_antidote_dir" 2>/dev/null
            curl -fsSL https://github.com/mattmc3/antidote/archive/refs/heads/main.tar.gz 2>/dev/null | tar -xz -C "$_antidote_dir" --strip-components=1 2>/dev/null
        fi
        if [ ! -f "$_antidote_dir/antidote.zsh" ] && command -v wget >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
            mkdir -p "$_antidote_dir" 2>/dev/null
            wget -qO- https://github.com/mattmc3/antidote/archive/refs/heads/main.tar.gz 2>/dev/null | tar -xz -C "$_antidote_dir" --strip-components=1 2>/dev/null
        fi
    fi
fi

# ------------------------------------------------------------------------------
# Compile & Load Plugins from plugins.txt
# ------------------------------------------------------------------------------
_plugins_txt="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.txt"
_plugins_zsh="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.zsh"
[ -f "$_plugins_txt" ] || _plugins_txt="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
[ -f "$_plugins_txt" ] || _plugins_txt="${ARCHCONFIG_DIR:-$HOME/archConfig}/core/config/zsh/plugins.txt"
_this_dir="${${(%):-%x}:A:h}"
if [ ! -f "$_plugins_txt" ] && [ -f "${_this_dir:h:h}/config/zsh/plugins.txt" ]; then
    _plugins_txt="${_this_dir:h:h}/config/zsh/plugins.txt"
fi
unset _this_dir
[ ! -f "$_plugins_zsh" ] && [ -f "${ZDOTDIR:-$HOME}/.zsh_plugins.zsh" ] && _plugins_zsh="${ZDOTDIR:-$HOME}/.zsh_plugins.zsh"

_loaded_plugins=0
if [ -f "$_antidote_dir/antidote.zsh" ] && [ -f "$_plugins_txt" ]; then
    source "$_antidote_dir/antidote.zsh"
    if [ -s "$_plugins_zsh" ] && [ "$_plugins_zsh" -nt "$_plugins_txt" ]; then
        source "$_plugins_zsh" 2>/dev/null && _loaded_plugins=1
    else
        mkdir -p "${_plugins_zsh:h}" 2>/dev/null
        antidote bundle < "$_plugins_txt" >| "$_plugins_zsh" 2>/dev/null
        if [ -s "$_plugins_zsh" ]; then
            source "$_plugins_zsh" 2>/dev/null && _loaded_plugins=1
        else
            antidote load "$_plugins_txt" 2>/dev/null && _loaded_plugins=1
        fi
    fi
elif [ -s "$_plugins_zsh" ]; then
    source "$_plugins_zsh" 2>/dev/null && _loaded_plugins=1
fi

if [ "$_loaded_plugins" -eq 0 ]; then
    # Fallback: check distro-packaged plugins without network overhead
    for _plugin_script in \
        /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
        /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh \
        /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-history-substring-search/zsh-history-substring-search.zsh" \
        /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
        [ -f "$_plugin_script" ] && source "$_plugin_script" 2>/dev/null
    done
fi
unset _antidote_dir _plugins_txt _plugins_zsh _plugin_script _loaded_plugins
