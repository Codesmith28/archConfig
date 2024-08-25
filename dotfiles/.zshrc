# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
plugins=(git ssh-agent zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# User configuration
[[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile'

# Starship prompt
eval "$(starship init zsh)"
eval "$(fzf --zsh)"

# FZF support
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# PNPM
export PNPM_HOME="/home/codesmith28/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# NVM and Node.js
export NVM_DIR="$HOME/.nvm"
# Lazy load NVM
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
    nvm $@
}
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Set default Node.js version in PATH
DEFAULT_NODE_VER_PATH="$(find $NVM_DIR/versions/node -maxdepth 1 -name "v${DEFAULT_NODE_VER#v}*" | sort -rV | head -n 1)"
[ -n "$DEFAULT_NODE_VER_PATH" ] && export PATH="$DEFAULT_NODE_VER_PATH/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "/home/codesmith28/.bun/_bun" ] && source "/home/codesmith28/.bun/_bun"

# Pipx
export PATH="$PATH:/home/codesmith28/.local/bin"

 # cat ~/.cache/wal/sequences

 eval $(thefuck --alias)
 eval $(thefuck --alias fk)
