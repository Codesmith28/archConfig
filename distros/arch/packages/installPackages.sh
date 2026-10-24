#!/bin/bash

echo "==> Restoring official repo packages"
sudo pacman -Syu --needed - <arch-repo.txt

echo "==> Installing yay"
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si

echo "==> Restoring AUR packages"
yay -S --needed - <arch-aur.txt

# install antidote and zsh-defer (idempotent, only if zsh is used/installed):
if command -v zsh >/dev/null 2>&1; then
    [ -d "${ZDOTDIR:-$HOME}/.antidote" ] || git clone --depth=1 https://github.com/mattmc3/antidote.git "${ZDOTDIR:-$HOME}/.antidote"
    [ -d "$HOME/.zsh-defer" ] || git clone https://github.com/romkatv/zsh-defer.git "$HOME/.zsh-defer"
fi
