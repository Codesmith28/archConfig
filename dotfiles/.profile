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

# For the profile:
# source ~/.profile

# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

alias c='clear'
alias e='exit'
alias nf='neofetch'
alias pf='pfetch'
alias ls='eza -a --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=2 --icons'
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
alias cleanup='~/dotfiles/scripts/cleanup.sh'
alias ml4w='~/dotfiles/apps/ML4W_Welcome-x86_64.AppImage'
alias battery='upower -i /org/freedesktop/UPower/devices/battery_BAT0 | bat'

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
alias confp='$EDITOR ~/dotfiles/picom/picom.conf'
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
alias cpp='cd ~/Projects/cse205-ds/ && code . && exit'

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
# PFETCH if on wm
# -----------------------------------------------------

pfetch

# -----------------------------------------------------
# STARSHIP export
# -----------------------------------------------------

export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# -----------------------------------------------------
# NNN
# -----------------------------------------------------

# NNN plugins and colors:
export NNN_PLUG='f:finder;o:fzopen;p:preview-tui;d:diffs;t:nmount;v:imgview;i:imgview'
export NNN_FCOLORS='FFFFFF310000000000000000'
export NNN_BMS='d:~/Downloads;t:~/Projects;h:~;D:~/dotfiles/'
export NNN_TERMINAL='kitty'
export NNN_FIFO="/tmp/nnn.fifo"
export PAGER="less -R"

# #cd on quit NNN:
n ()
{
    # Block nesting of nnn in subshells
    [ "${NNNLVL:-0}" -eq 0 ] || {
        echo "nnn is already running"
        return
    }
    
    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #      NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    
    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef
    
    # The command builtin allows one to alias nnn to n, if desired, without
    # making an infinitely recursive alias
    command nnn "$@"
    
    [ ! -f "$NNN_TMPFILE" ] || {
        . "$NNN_TMPFILE"
        rm -f "$NNN_TMPFILE" > /dev/null
    }
}

nnn-preview ()
{
    # Block nesting of nnn in subshells
    if [ -n "$NNNLVL" ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi
    
    # The default behaviour is to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to see.
    # To cd on quit only on ^G, remove the "export" and set NNN_TMPFILE *exactly* as this:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    
    # This will create a fifo where all nnn selections will be written to
    NNN_FIFO="$(mktemp --suffix=-nnn -u)"
    export NNN_FIFO
    (umask 077; mkfifo "$NNN_FIFO")
    
    # Preview command
    preview_cmd="/path/to/preview_cmd.sh"
    
    # Use `tmux` split as preview
    if [ -e "${TMUX%%,*}" ]; then
        tmux split-window -e "NNN_FIFO=$NNN_FIFO" -dh "$preview_cmd"
        
        # Use `xterm` as a preview window
        elif (which xterm &> /dev/null); then
        xterm -e "$preview_cmd" &
        
        # Unable to find a program to use as a preview window
    else
        echo "unable to open preview, please install tmux or xterm"
    fi
    
    nnn "$@"
    
    rm -f "$NNN_FIFO"
}

# -----------------------------------------------------
# TMUX
# -----------------------------------------------------

# make alases for tmux:
alias tmux='tmux -2'
alias ta='tmux attach -t'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'
alias tn='tmux new-session -s'
alias ts='tmux switch -t'
alias tks='tmux kill-session -a'

# -----------------------------------------------------
# Files and code
# -----------------------------------------------------

vsc() {
    code "$1" && exit
}

alias thunar='setsid thunar'
alias nautilus='setsid nautilus'
alias fzf='fzf --preview="bat --color=always --style=header,grid --line-range :500 {}"'

# -----------------------------------------------------
# App development
# -----------------------------------------------------

# export ANDROID_HOME=/opt/android-sdk
# export PATH=$PATH:$ANDROID_HOME/emulator
# export PATH=$PATH:$ANDROID_HOME/tools
# export PATH=$PATH:$ANDROID_HOME/tools/bin
# export PATH=$PATH:$ANDROID_HOME/platform-tools

# -----------------------------------------------------
# Yazi file manager:
# -----------------------------------------------------

function y() {
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
