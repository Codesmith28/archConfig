# ~/.bashrc.d/01-aliases.bash - Shell aliases and shortcuts

# ------------------------------------------------------------------------------
# Navigation & Listing
# ------------------------------------------------------------------------------
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons'
    alias ll='eza -l --icons'
    alias la='eza -a --icons'
    alias lla='eza -al --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

alias pj='cd ~/Projects/'

# ------------------------------------------------------------------------------
# Shell Navigation & Quick Actions
# ------------------------------------------------------------------------------
alias c='clear'
alias e='exit'
alias cf='clear && fastfetch'

# ------------------------------------------------------------------------------
# Sourcing & Environment Management
# ------------------------------------------------------------------------------
alias sourceb='source ~/.bashrc'
alias sourcep='source ~/.profile'
alias source_venv='source ./venv/bin/activate'

# ------------------------------------------------------------------------------
# Quick Configuration Editing
# ------------------------------------------------------------------------------
alias confb='${EDITOR:-nvim} ~/.bashrc'
alias confp='${EDITOR:-nvim} ~/.profile'
alias confa='${EDITOR:-nvim} ~/.bashrc.d/01-aliases.bash'
alias confn='${EDITOR:-nvim} ~/.config/nvim/'
alias confg='${EDITOR:-nvim} ~/.config/ghostty/config'

# ------------------------------------------------------------------------------
# Developer Tools & Utilities
# ------------------------------------------------------------------------------
alias open='xdg-open'
alias agyd='agy --dangerously-skip-permissions'
alias lg='lazygit'
alias lzd='lazydocker'
