export PATH="$HOME/.local/bin:$PATH"
#    _               _
#   | |__   __ _ ___| |__  _ __ ___
#   | '_ \ / _` / __| '_ \| '__/ __|
#  _| |_) | (_| \__ \ | | | | | (__
# (_)_.__/ \__,_|___/_| |_|_|  \___|
#
# -----------------------------------------------------
# ~/.bashrc
# -----------------------------------------------------

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ '

# Define Editor
export EDITOR=vim
source "$HOME/.profile"

# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

alias c='clear'
alias e='exit'
alias nf='fastfetch'
alias pf='fastfetch'
alias ls='eza -a --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=1 --icons'
alias matrix='cmatrix'
alias wifi='nmtui'
alias dot="cd ~/dotfiles"

# -----------------------------------------------------
# GIT
# -----------------------------------------------------

alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash; git pull"
alias gcheck="git checkout"
alias gcredential="git config credential.helper store"

# -----------------------------------------------------
# EDIT CONFIG FILES
# -----------------------------------------------------

alias confq='$EDITOR ~/dotfiles/qtile/config.py'
alias confp='$EDITOR ~/dotfiles/picom/picom.conf'
alias confb='$EDITOR ~/dotfiles/.bashrc'

# -----------------------------------------------------
# START STARSHIP
# -----------------------------------------------------
eval "$(starship init bash)"

# -----------------------------------------------------
# PFETCH if on wm
# -----------------------------------------------------
echo ""
if [[ $(tty) == *"pts"* ]]; then
    fastfetch
else
    if [ -f /bin/qtile ]; then
        echo "Start Qtile X11 with command Qtile"
    fi
    if [ -f /bin/hyprctl ]; then
        echo "Start Hyprland with command Hyprland"
    fi
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
export PATH="$HOME/.cargo/bin:$PATH"
. "$HOME/.cargo/env"

#
# -----------------------------------------------------
# fzf
# -----------------------------------------------------

alias fzf="fzf --style full --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

ts() {
    local selection target

    # Define a literal tab variable to make the tmux format string bulletproof
    # against accidental space-conversions in editors.
    local tab=$'\t'

    # 1. Generate the list using a hidden Tab-separated column for the exact target
    selection=$(
        tmux list-sessions -F "#{session_name}${tab}#S: #{session_windows} windows" 2>/dev/null | while IFS=$'\t' read -r s_target s_display; do
            printf "%s\t%s\n" "$s_target" "$s_display"

            tmux list-windows -t "$s_target" -F "#{session_name}:#{window_index}${tab}│  ├─> #{window_index}: #W#{?window_active,*,} (#{window_panes} panes)" | while IFS=$'\t' read -r w_target w_display; do
                printf "%s\t%s\n" "$w_target" "$w_display"
            done
        done | fzf --query="$1" --reverse --height=80% --prompt="TMUX > " \
            --delimiter='\t' \
            --with-nth=2 \
            --preview-window="right:50%:wrap" \
            --preview="tmux capture-pane -e -p -t {1} 2>/dev/null"
    )

    # 2. Extract the hidden target (cut splits by Tab by default)
    if [ -n "$selection" ]; then
        target=$(echo "$selection" | cut -f1)

        # 3. Robust switch/attach logic
        # Check $TERM to genuinely verify we are inside an active tmux pane
        if [[ "$TERM" == screen* ]] || [[ "$TERM" == tmux* ]]; then
            # We are actively inside a tmux pane
            tmux switch-client -t "$target"
        else
            # We are outside tmux (e.g., bare VSCode terminal).
            # We unset the $TMUX variable for this specific command to prevent
            # the "sessions should be nested with care" error if VSCode inherited it.
            env -u TMUX tmux attach-session -t "$target"
        fi
    fi
}

alias ivm='$EDITOR $(fzf -m --preview="bat --color=always --style=header,grid --line-range :500 {}")'

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

export PATH="$HOME/go/bin:$PATH"
