# ==============================================================================
# 05-starship.zsh - Prompt Configuration (Starship)
# ==============================================================================

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
