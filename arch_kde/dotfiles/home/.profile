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
export BROWSER=nautilus

# alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias ltspice='ltspice --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias res_idle='~/dotfiles/hypr/scripts/restart-hypridle.sh'

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
alias shutdown='systemctl poweroff'
alias v='$EDITOR'
# alias vim='$EDITOR'
alias ts='~/dotfiles/scripts/snapshot.sh'
alias matrix='cmatrix -u 2'
alias wifi='nmtui'
alias od='~/private/onedrive.sh'
alias tw='~/dotfiles/waybar/toggle.sh'
alias winclass="xprop | grep 'CLASS'"
alias dot="cd ~/.config"
alias hypr="cd ~/dotfiles/hypr"
alias cleanup='~/dotfiles/scripts/cleanup.sh'
alias ml4w='~/dotfiles/apps/ML4W_Welcome-x86_64.AppImage'
alias copy='xclip -selection clipboard'
# alias bat='batcat --theme=base16'
# alias update_all='sudo apt update && sudo apt full-upgrade'
alias update_all='yay -Syu'

alias source_z='source ~/.zshrc'
alias source_venv='source venv/bin/activate'
alias prime-run='env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia'

# -----------------------------------------------------
# System Controls
# -----------------------------------------------------

bu() {
    if [[ -z $1 ]]; then
        echo "Please specify a percentage to increase, e.g., bu 10"
    else
        brightnessctl set "$1"%+
    fi
}
bd() {
    if [[ -z $1 ]]; then
        echo "Please specify a percentage to decrease, e.g., bd 10"
    else
        brightnessctl set "$1"%-
    fi
}
vu() {
    if [[ -z $1 ]]; then
        echo "Please specify a percentage to increase, e.g., vu 10"
    else
        pactl set-sink-volume @DEFAULT_SINK@ +"$1"%
    fi
}
vd() {
    if [[ -z $1 ]]; then
        echo "Please specify a percentage to decrease, e.g., vd 10"
    else
        pactl set-sink-volume @DEFAULT_SINK@ -"$1"%
    fi
}

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
ghcs() {
    gh copilot suggest "$1"
}

# -----------------------------------------------------
# SCRIPTS
# -----------------------------------------------------

alias ascii='~/dotfiles/scripts/figlet.sh'
alias fontsearch='~/dotfiles/scripts/fontsearch.sh'

# -----------------------------------------------------
# EDIT CONFIG FILES
# -----------------------------------------------------

alias confq='$EDITOR ~/dotfiles/qtile/config.py'
alias confp='$EDITOR ~/.profile'
alias confb='$EDITOR ~/.bashrc'
alias confz='$EDITOR ~/.zshrc'
alias confn='$EDITOR ~/.config/nvim'

# -----------------------------------------------------
# GoQuant
# -----------------------------------------------------

alias reset_db='~/.config/work/reset_db.sh'
alias fastapiup='cd ~/gotrade/fastapi && source venv/bin/activate && poetry run uvicorn gotrade.src.main:app --host 0.0.0.0 --port 8001'

# -----------------------------------------------------
# EDIT NOTES
# -----------------------------------------------------

notes() {
    local orig="$PWD"
    local notes_dir=~/Projects/Obsidian_Vault/_notes
    mkdir -p "$notes_dir"
    cd "$notes_dir"
    ${EDITOR:-nvim} .
    cd "$orig"
}

# -----------------------------------------------------
# MINECRAFT
# -----------------------------------------------------

alias MC='java -jar ~/.minecraft/TLauncher*.jar'

# -----------------------------------------------------
# SYSTEM
# -----------------------------------------------------

alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias setkb='setxkbmap us;echo "Keyboard set back to us."'
# mntd() {
#     command -v ntfs-3g >/dev/null 2>&1 || {
#         echo >&2 "ntfs-3g is not installed. Installing..."
#         yay -S ntfs-3g
#     }
#     [ -d "/media/codesmith28/D" ] || mkdir -p /media/codesmith28/D
#     sudo mount /dev/nvme0n1p4 /home/run/media/localdiskD && echo "Disk successfully mounted at /home/run/media/localdiskD"
# }
alias D='cd /media/codesmith28/D'
fixD() {
    sudo umount /media/codesmith28/D && echo "Disk unmounted."
}
alias battery='upower -i /org/freedesktop/UPower/devices/battery_BAT0 | bat'
# alias netrs='sudo systemctl restart NetworkManager && sudo systemctl restart iwd'
netrs() {
    sudo systemctl restart NetworkManager && echo "NetworkManager restarted."
    # sudo systemctl restart iwd && echo "iwd restarted."
}

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
# Set blinking underline cursor (only when not in Neovim)
if [ "$TERM" = "xterm-256color" ] && [ -z "$VIM" ]; then
    echo -ne '\e[3 q'
fi

alias pj='cd ~/Projects'
alias thunar='setsid thunar'
alias files='setsid $BROWSER'
alias obsidian='setsid obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias obsi='setsid obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland && exit -f'
alias fzf='fzf --preview="bat --color=always --style=header,grid --line-range :500 {}"'
# alias ivm='$EDITOR $(fzf -m --preview="bat --color=always --style=header,grid --line-range :500 {}")'
alias ivm='f() { local file; file=$(tv); [ -n "$file" ] && "$EDITOR" "$file"; }; f'

runcpp() {
    # filename=$(echo $1 | cut -f 1 -d '.')
    # clang++ "$1" -o $filename && ./$filename
    clang++ "$1" -o run && "./run"
    rm run
}
runcc() {
    clang "$1" -o run && "./run"
    rm run
}

alias cpp='cd ~/Projects/cp/ && code . && exit'
alias lazy='~/Downloads/lazyAi'
alias calc='~/.config/scripts/auto_qalc.sh'

# -----------------------------------------------------
# Yazi file manager exit on quit:
# -----------------------------------------------------

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

spf() {
    os=$(uname -s)

    # Linux
    if [[ "$os" == "Linux" ]]; then
        export SPF_LAST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
    fi

    # macOS
    if [[ "$os" == "Darwin" ]]; then
        export SPF_LAST_DIR="$HOME/Library/Application Support/superfile/lastdir"
    fi

    command spf "$@"

    [ ! -f "$SPF_LAST_DIR" ] || {
        . "$SPF_LAST_DIR"
        rm -f -- "$SPF_LAST_DIR" >/dev/null
    }
}

alias dafq='thefuck'

rog() {
    sudo rogauracore "$@"
    sudo systemctl restart upower.service
}

#   -----------------------------------------------------
#   GEMINI api Key
#   -----------------------------------------------------
# Load only GEMINI_API_KEY from .env, without leaking other variables
if [ -f "$HOME/.env" ]; then
    export GEMINI_API_KEY="$(grep '^GEMINI_API_KEY=' "$HOME/.env" | cut -d '=' -f2- | sed 's/^"//;s/"$//')"
fi

#  -----------------------------------------------------
#  fix kitty on ssh
#  -----------------------------------------------------

[ "$TERM" = "xterm-kitty" ] && export TERM=xterm-256color

# -----------------------------------------------------
# BIG DATA ALIASES
# -----------------------------------------------------

alias hadoop_start='~/University/BigData/start_hadoop.sh'
hdfs-tree() {
    hdfs dfs -ls -R "$1" | awk '{print $8}' | sed 's/[^/]*\//|   /g;s/|   \([^|]\)/+--- \1/'
}
. "$HOME/.cargo/env"
