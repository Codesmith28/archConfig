# ========== Oh My Zsh config ==========
# export ZSH="$HOME/.oh-my-zsh"
# DISABLE_AUTO_UPDATE="true"
# DISABLE_UPDATE_PROMPT="true"
# ZSH_DISABLE_COMPFIX=true
#
# plugins=(git zsh-autosuggestions) # remove zsh-syntax-highlighting here; load it last
# source $ZSH/oh-my-zsh.sh
# Use cached compinit for fast startup

autoload -Uz compinit
ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump"
zstyle ':completion:*' rehash true
compinit -C

# ---------- Antidote ----------
source ~/.antidote/antidote.zsh
antidote load ~/.config/zsh/plugins.txt

# ============ Basic config ============
[[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile'
eval "$(starship init zsh)"

# ========== Deferred plugins ==========
source ~/.zsh-defer/zsh-defer.plugin.zsh 2>/dev/null

# These are heavy → defer them
[ -f ~/.fzf.zsh ] && zsh-defer source ~/.fzf.zsh
zsh-defer eval "$(tv init zsh)"

# zsh-syntax-highlighting must load last → defer!
zsh-defer source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# ========== PNPM ==========
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"


# ========== Lazy-load NVM ==========
export NVM_DIR="$HOME/.nvm"
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" --no-use
    nvm "$@"
}
[ -s "$NVM_DIR/bash_completion" ] && zsh-defer source "$NVM_DIR/bash_completion"


# Default Node.js version in PATH (only run if variable set)
if [[ -n "$DEFAULT_NODE_VER" ]]; then
  DEFAULT_NODE_VER_PATH="$(find "$NVM_DIR/versions/node" -maxdepth 1 -name "v${DEFAULT_NODE_VER#v}*" | sort -rV | head -n 1)"
  [[ -n "$DEFAULT_NODE_VER_PATH" ]] && export PATH="$DEFAULT_NODE_VER_PATH/bin:$PATH"
fi


# ========== Bun ==========
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# bun autocomplete is slow → defer
[ -s "$HOME/.bun/_bun" ] && zsh-defer source "$HOME/.bun/_bun"


# ========== Pyenv ==========
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
# VERY heavy init → defer! [don't use this if pyenv installed from AUR]
# zsh-defer eval "$(pyenv init --path)"
# zsh-defer eval "$(pyenv init -)"
# zsh-defer eval "$(pyenv virtualenv-init -)"


# ========== Go Path ==========
export PATH="$PATH:$(go env GOPATH)/bin"


# ========== Java Path ==========
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin
export PATH=$HOME/.local/bin:$PATH

# bun completions
[ -s "/home/codesmith28/.bun/_bun" ] && source "/home/codesmith28/.bun/_bun"
