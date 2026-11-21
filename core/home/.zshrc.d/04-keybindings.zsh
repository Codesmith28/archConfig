# ==============================================================================
# 04-keybindings.zsh - Terminal Keybindings & History Search
# ==============================================================================

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
