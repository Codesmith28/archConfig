# ========== Oh My Zsh config ==========
autoload -Uz compinit
ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump"
zstyle ':completion:*' rehash true
compinit -C

# ---------- Antidote ----------
source ~/.antidote/antidote.zsh
antidote load ~/.config/zsh/plugins.txt

# ============ Basic setup and aliases ============
[[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile'
[[ -e ~/.config/work/work.sh ]] && emulate sh -c 'source ~/.config/work/work.sh'

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# ========== Deferred plugins ==========
source ~/.zsh-defer/zsh-defer.plugin.zsh 2>/dev/null

# fzf
[ -f ~/.fzf.zsh ] && zsh-defer source ~/.fzf.zsh
source <(fzf --zsh)

# zsh zsh-syntax-highlighting
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


# nodejs
if [[ -n "$DEFAULT_NODE_VER" ]]; then
  DEFAULT_NODE_VER_PATH="$(find "$NVM_DIR/versions/node" -maxdepth 1 -name "v${DEFAULT_NODE_VER#v}*" | sort -rV | head -n 1)"
  [[ -n "$DEFAULT_NODE_VER_PATH" ]] && export PATH="$DEFAULT_NODE_VER_PATH/bin:$PATH"
fi


# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# bun autocomplete is slow → defer
[ -s "$HOME/.bun/_bun" ] && zsh-defer source "$HOME/.bun/_bun"


# ========== Pyenv ==========
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
zsh-defer eval "$(pyenv init --path)"
zsh-defer eval "$(pyenv init -)"


# ========== Go Path ==========
export PATH="$PATH:$(go env GOPATH)/bin"


export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# bun completions
[ -s "/home/codesmith28/.bun/_bun" ] && source "/home/codesmith28/.bun/_bun"

# brew
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# ========== Java Path ==========
# Added by setup-java-toolchains.sh
export JAVA_11_HOME="/Library/Java/JavaVirtualMachines/openjdk-11.jdk/Contents/Home"
export JAVA_21_HOME="/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home"
export JAVA_HOME="$JAVA_21_HOME"

export PATH="$HOME/.local/bin:$PATH"

eval "$(/usr/libexec/path_helper)"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Added by Antigravity
export PATH="/Users/codesmith28/.antigravity/antigravity/bin:$PATH"
export PATH=~/.adaptive/bin/:$PATH

# CP fixes
export CC=gcc-15
export CXX=g++-15


# Added by Antigravity CLI installer
export PATH="/Users/codesmith28/.local/bin:$PATH"

# Added by Antigravity IDE
export PATH="/Users/codesmith28/.antigravity-ide/antigravity-ide/bin:$PATH"

# Added by Antigravity IDE
export PATH="/Users/codesmith28/.antigravity-ide/antigravity-ide/bin:$PATH"
