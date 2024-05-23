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

# For the profile:
source ~/.profile

# -----------------------------------------------------
# Window Managers
# -----------------------------------------------------

alias Qtile='startx'
# Qtile
alias res1='xrandr --output DisplayPort-0 --mode 2560x1440 --rate 120'
alias res2='xrandr --output DisplayPort-0 --mode 1920x1080 --rate 120'
export PATH="/usr/lib/ccache/bin/:$PATH"
# Hyprland with Hyprland

# -----------------------------------------------------
# VIRTUAL MACHINE
# -----------------------------------------------------

alias vm='~/private/launchvm.sh'
alias lg='~/dotfiles/scripts/looking-glass.sh'
alias vmstart='virsh --connect qemu:///system start win11'
alias vmstop='virsh --connect qemu:///system destroy win11'

# -----------------------------------------------------
# START STARSHIP
# -----------------------------------------------------

eval "$(starship init bash)"

# -----------------------------------------------------
# PYWAL
# -----------------------------------------------------

# cat ~/.cache/wal/sequences

# -----------------------------------------------------
# Development
# -----------------------------------------------------

# gh copilot alias
# eval "$(gh copilot alias -- zsh)"

# fzf suppoprt
eval "$(fzf --zsh)"

# -----------------------------------------------------
# PNPM
# -----------------------------------------------------

# # pnpm
# export PNPM_HOME="/home/codesmith28/.local/share/pnpm"
# case ":$PATH:" in
#   *":$PNPM_HOME:"*) ;;
#   *) export PATH="$PNPM_HOME:$PATH" ;;
# esac
# # pnpm end
#

# -----------------------------------------------------
# NVM and NODE
# -----------------------------------------------------

export NVM_DIR="$HOME/.nvm"

# This lazy loads nvm
nvm() {
  unset -f nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use # This loads nvm
  nvm $@
}

# This loads nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# This resolves the path to the default node version
DEFAULT_NODE_VER_PATH="$(find $NVM_DIR/versions/node -maxdepth 1 -name "v${DEFAULT_NODE_VER#v}*" | sort -rV | head -n 1)"

# This adds the default node version path to PATH
if [ ! -z "$DEFAULT_NODE_VER_PATH" ]; then
  export PATH="$DEFAULT_NODE_VER_PATH/bin:$PATH"
fi

# -----------------------------------------------------
# BUN
# -----------------------------------------------------

# add to ~/.bashrc
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
