#!/bin/bash

echo "==> Restoring official repo packages"
sudo pacman -Syu --needed - <arch-repo.txt

echo "==> Installing yay"
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si

echo "==> Restoring AUR packages"
yay -S --needed - <arch-aur.txt
