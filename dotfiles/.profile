#                     __ _ _
#    _ __  _ __ ___  / _(_) | ___
#   | '_ \| '__/ _ \| |_| | |/ _ \
#  _| |_) | | | (_) |  _| | |  __/
# (_) .__/|_|  \___/|_| |_|_|\___|
#   |_|

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ '

# Define Editor
export EDITOR=nvim
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias ltspice='ltspice --enable-features=UseOzonePlatform --ozone-platform=wayland'

# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

alias c='clear'
alias e='exit'
alias nf='neofetch'
alias pf='pfetch'
alias ff='fastfetch'
alias ls='eza -a --icons'
alias ll='eza -al --icons'
lt () {
    local level=${1:-1}
    eza -a --tree --level=$level --icons
}
alias shutdown='systemctl poweroff'
alias v='$EDITOR'
alias vim='$EDITOR'
alias ts='~/dotfiles/scripts/snapshot.sh'
alias matrix='cmatrix -u 2'
alias wifi='nmtui'
alias od='~/private/onedrive.sh'
alias rw='~/dotfiles/waybar/reload.sh'
alias winclass="xprop | grep 'CLASS'"
alias dot="cd ~/dotfiles"
alias hypr="cd ~/dotfiles/hypr"
alias cleanup='~/dotfiles/scripts/cleanup.sh'
alias ml4w='~/dotfiles/apps/ML4W_Welcome-x86_64.AppImage'
alias battery='upower -i /org/freedesktop/UPower/devices/battery_BAT0 | bat'
alias netrs='sudo systemctl restart NetworkManager'

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
alias lg='lazygit'
alias gcheck="git checkout"

# -----------------------------------------------------
# SCRIPTS
# -----------------------------------------------------

alias gr='python ~/dotfiles/scripts/growthrate.py'
alias ChatGPT='python ~/mychatgpt/mychatgpt.py'
alias chat='python ~/mychatgpt/mychatgpt.py'
alias ascii='~/dotfiles/scripts/figlet.sh'

# -----------------------------------------------------
# EDIT CONFIG FILES
# -----------------------------------------------------

alias confq='$EDITOR ~/dotfiles/qtile/config.py'
alias confp='$EDITOR ~/dotfiles/.profile'
alias confb='$EDITOR ~/dotfiles/.bashrc'
alias confz='$EDITOR ~/dotfiles/.zshrc'

# -----------------------------------------------------
# EDIT NOTES
# -----------------------------------------------------

alias notes='$EDITOR ~/notes.txt'
# alias runcpp='clang++ run.cpp -o run && ./run'
runcpp() {
    clang++ "$1" -o run.exe && ./run.exe
}
alias cpp='cd ~/Projects/cp/ && code . && exit'

# -----------------------------------------------------
# MINECRAFT
# -----------------------------------------------------

alias MC='java -jar ~/.minecraft/TLauncher*.jar'

# -----------------------------------------------------
# SYSTEM
# -----------------------------------------------------

alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias setkb='setxkbmap us;echo "Keyboard set back to us."'
mntd() {
    command -v ntfs-3g >/dev/null 2>&1 || { echo >&2 "ntfs-3g is not installed. Installing..."; yay -S ntfs-3g; }
    [ -d "/home/run/media/localdiskD" ] || mkdir -p /home/run/media/localdiskD
    sudo mount /dev/nvme0n1p4 /home/run/media/localdiskD && echo "Disk successfully mounted at /home/run/media/localdiskD"
}
alias D='cd /home/run/media/localdiskD'

# -----------------------------------------------------
# PFETCH/fastfetch
# -----------------------------------------------------

# ff

# -----------------------------------------------------
# STARSHIP export
# -----------------------------------------------------

export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# -----------------------------------------------------
# DOCKER
# -----------------------------------------------------

export DOCKER_HOST=unix:///var/run/docker.sock

# -----------------------------------------------------
# Files and code
# -----------------------------------------------------

vsc() {
    code "$1" && exit
}

alias proj='cd ~/Projects'

neovide() {
    setsid -f neovide "$1" && exit
}

alias thunar='setsid thunar'
alias files='setsid nautilus'
alias fzf='fzf --preview="bat --color=always --style=header,grid --line-range :500 {}"'
alias ivm='$EDITOR $(fzf -m --preview="bat --color=always --style=header,grid --line-range :500 {}")'

# -----------------------------------------------------
# Yazi file manager:
# -----------------------------------------------------

function lf() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# -----------------------------------------------------
# Gh CLI
# -----------------------------------------------------

ghcs () {
    gh copilot suggest "$1"
}

# -----------------------------------------------------
# wayland
# -----------------------------------------------------
