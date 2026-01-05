#!/bin/bash
set -e

echo "==> Installing brew formulae"
xargs brew install <brew-formulae.txt

echo "==> Installing brew casks"
xargs brew install --cask <brew-casks.txt

# install antidote and zsh-defer:
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$HOME}/.antidote
git clone https://github.com/romkatv/zsh-defer.git ~/.zsh-defer
