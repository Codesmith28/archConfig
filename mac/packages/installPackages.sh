#!/bin/bash
set -e

command -v brew >/dev/null || {
    echo "Homebrew not installed"
    exit 1
}

echo "==> Installing explicit brew packages"
xargs brew install <brew-explicit.txt

echo "==> Installing brew casks"
xargs brew install --cask <brew-casks.txt

# Zsh tooling (idempotent)
[ -d "${ZDOTDIR:-$HOME}/.antidote" ] ||
    git clone --depth=1 https://github.com/mattmc3/antidote.git \
        "${ZDOTDIR:-$HOME}/.antidote"

[ -d "$HOME/.zsh-defer" ] ||
    git clone https://github.com/romkatv/zsh-defer.git \
        "$HOME/.zsh-defer"

# install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
