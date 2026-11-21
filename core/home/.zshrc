# ==============================================================================
# archConfig Universal Zsh Configuration
# ==============================================================================

# 1. Environment & Base PATH (Source ~/.profile first)
if [ -z "$_SOURCING_PROFILE" ] && [ -f "$HOME/.profile" ]; then
    _SOURCING_ZSHRC=1
    source "$HOME/.profile"
    unset _SOURCING_ZSHRC
fi

# 2. Source Modular Zsh Configurations (~/.zshrc.d/*.zsh)
# Pure Zsh-First architecture: Strictly reads native modular Zsh configurations
_dir="${ZDOTDIR:-$HOME}/.zshrc.d"
[ -d "$_dir" ] || _dir="${${(%):-%x}:A:h}/.zshrc.d"
for rc in "$_dir"/*.zsh(N); do [ -r "$rc" ] && source "$rc"; done
unset _dir rc

# 3. Workstation Overrides & Local PATH Hygiene
[ -f "$HOME/.config/work/work.sh" ] && source "$HOME/.config/work/work.sh"
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
