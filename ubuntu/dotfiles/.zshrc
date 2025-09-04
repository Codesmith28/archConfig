# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
# plugins=(git ssh-agent zsh-autosuggestions zsh-syntax-highlighting)
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# User configuration
[[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile'

# Starship prompt
eval "$(starship init zsh)"

# FZF support
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Television support:
# ctrl + r -> shell history
# ctrl + t -> smart autocompletion
eval "$(tv init zsh)"

# PNPM
export PNPM_HOME="$HOME/.local/share/pnpm"
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
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Pipx
# Pyenv setup
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Go Path
export PATH="$PATH:$(go env GOPATH)/bin"

# Java Path
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

# Hadoop Path
export HADOOP_HOME="$HOME/hadoop-2.7.3"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HADOOP_MAPRED_HOME="$HADOOP_HOME"
export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_HOME"
export YARN_HOME="$HADOOP_HOME"
export PATH="$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin"

