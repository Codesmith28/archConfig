#    _ __  _ __ ___  / _(_) | ___
#   | '_ \| '__/ _ \| |_| | |/ _ \
#  _| |_) | | | (_) |  _| | |  __/
# (_) .__/|_|  \___/|_| |_|_|\___|
#   |_|

# Define Editor
export EDITOR=vim
export PATH="$HOME/.local/bin:$PATH"


# Force color support
export CLICOLOR=1
export TERM=xterm-256color

force_color_prompt=yes
export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

alias c='clear'
alias e='exit'
alias nf='neofetch'
alias pf='pfetch'
alias ff='fastfetch'
alias cf='c && fastfetch'
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -a --icons'
alias lla='eza -al --icons'
lt() {
    local level=${1:-1}
    eza -a --tree --level="$level" --icons
}
alias dot="cd ~/.config"
alias bat='batcat --theme=base16'
# alias update_all='sudo apt update && sudo apt full-upgrade'

alias source_z='source ~/.zshrc'
alias source_b='source ~/.bashrc'
alias source_venv='source venv/bin/activate'

alias lg='lazygit'

alias gcl-work='git -c core.sshCommand="ssh -i ~/.ssh/id_work" clone'
alias gcl-personal='git -c core.sshCommand="ssh -i ~/.ssh/id_personal" clone'
alias ssh-work='ssh -i "~/.ssh/id_work"'

# -----------------------------------------------------
# EDIT CONFIG FILES
# -----------------------------------------------------

alias confq='$EDITOR ~/dotfiles/qtile/config.py'
alias confp='$EDITOR ~/.profile'
alias confb='$EDITOR ~/.bashrc'
alias confz='$EDITOR ~/.zshrc'
alias confn='$EDITOR ~/.config/nvim'

alias python='python3'
alias fzf='fzf --preview="[[ -d {} ]] && eza --tree --level=2 --icons {} | head -200 || batcat --color=always --style=header,grid --line-range :500 {} 2>/dev/null"'

# kubectl aliases:
alias k='kubectl -n codesmith'
alias work='cd ~/work/'

[ -f ~/.fzf.bash ] && source ~/.fzf.bash


