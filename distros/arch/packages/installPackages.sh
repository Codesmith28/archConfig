#!/bin/bash

echo "==> Restoring official repo packages"
sudo pacman -Syu --needed - <arch-repo.txt

echo "==> Installing yay"
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si

echo "==> Restoring AUR packages"
yay -S --needed - <arch-aur.txt

# install antidote and zsh-defer:
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$HOME}/.antidote
git clone https://github.com/romkatv/zsh-defer.git ~/.zsh-defer
