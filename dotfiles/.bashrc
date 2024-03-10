#    _               _
#   | |__   __ _ ___| |__  _ __ ___
#   | '_ \ / _` / __| '_ \| '__/ __|
#  _| |_) | (_| \__ \ | | | | | (__
# (_)_.__/ \__,_|___/_| |_|_|  \___|
#
# by Stephan Raabe (2023)
# -----------------------------------------------------
# ~/.bashrc
# -----------------------------------------------------

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ '

# Define Editor
export EDITOR=nvim

# For the profile:
# source ~/.profile

# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

alias c='clear'
alias nf='neofetch'
alias pf='pfetch'
alias ls='eza -a --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=2 --icons'
alias shutdown='systemctl poweroff'
alias v='$EDITOR'
alias ts='~/dotfiles/scripts/snapshot.sh'
alias matrix='cmatrix b'
alias wifi='nmtui'
alias od='~/private/onedrive.sh'
alias rw='~/dotfiles/waybar/reload.sh'
alias winclass="xprop | grep 'CLASS'"
alias dot="cd ~/dotfiles"
alias cleanup='~/dotfiles/scripts/cleanup.sh'
alias ml4w='~/dotfiles/apps/ML4W_Welcome-x86_64.AppImage'

# -----------------------------------------------------
# Window Managers
# -----------------------------------------------------

alias Qtile='startx'
# Hyprland with Hyprland

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

# -----------------------------------------------------
# SCRIPTS
# -----------------------------------------------------

alias gr='python ~/dotfiles/scripts/growthrate.py'
alias ChatGPT='python ~/mychatgpt/mychatgpt.py'
alias chat='python ~/mychatgpt/mychatgpt.py'
alias ascii='~/dotfiles/scripts/figlet.sh'

# -----------------------------------------------------
# VIRTUAL MACHINE
# -----------------------------------------------------

alias vm='~/private/launchvm.sh'
alias lg='~/dotfiles/scripts/looking-glass.sh'
alias vmstart='virsh --connect qemu:///system start win11'
alias vmstop='virsh --connect qemu:///system destroy win11'

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


# -----------------------------------------------------
# SYSTEM
# -----------------------------------------------------

alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias setkb='setxkbmap de;echo "Keyboard set back to de."'
alias mntD='command -v ntfs-3g >/dev/null 2>&1 || { echo >&2 "ntfs-3g is not installed. Installing..."; yay -S ntfs-3g; }; [ -d "/home/run/media/localdiskD" ] || mkdir -p /home/run/media/localdiskD; sudo mount /dev/nvme0n1p4 /home/run/media/localdiskD && echo "Disk successfully mounted at /home/run/media/localdiskD"'

# -----------------------------------------------------
# SCREEN RESOLUTINS
# -----------------------------------------------------

# Qtile
alias res1='xrandr --output DisplayPort-0 --mode 2560x1440 --rate 120'
alias res2='xrandr --output DisplayPort-0 --mode 1920x1080 --rate 120'

export PATH="/usr/lib/ccache/bin/:$PATH"

# -----------------------------------------------------
# START STARSHIP
# -----------------------------------------------------
eval "$(starship init bash)"

# -----------------------------------------------------
# PYWAL
# -----------------------------------------------------
cat ~/.cache/wal/sequences

# -----------------------------------------------------
# PFETCH if on wm
# -----------------------------------------------------

echo ""
if [[ $(tty) == *"pts"* ]]; then
    pfetch
else
    if [ -f /bin/qtile ]; then
        echo "Start Qtile X11 with command Qtile"
    fi
    if [ -f /bin/hyprctl ]; then
        echo "Start Hyprland with command Hyprland"
    fi
fi



# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion



# # pnpm
# export PNPM_HOME="/home/codesmith28/.local/share/pnpm"
# case ":$PATH:" in
#   *":$PNPM_HOME:"*) ;;
#   *) export PATH="$PNPM_HOME:$PATH" ;;
# esac
# # pnpm end
#



# add to ~/.bashrc
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"



# NNN plugins and colors:
export NNN_PLUG='f:finder;o:fzopen;p:preview-tui;d:diffs;t:nmount;v:imgview;i:imgview'
export NNN_FCOLORS='FFFFFF310000000000000000'
export NNN_TERMINAL='alacritty --title preview-tui'
export NNN_FIFO="/tmp/nnn.fifo"
export PAGER="less -R"

#cd on quit NNN:
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
