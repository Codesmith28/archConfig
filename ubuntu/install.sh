#!/bin/bash

# Installation script for ubuntu

set -e

echo "Starting installation..."

# ----------------------------------------------------
# Update and Upgrade
# ----------------------------------------------------
sudo apt install software-properties-common
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt-get update
sudo apt-get full-upgrade -y

# ----------------------------------------------------
# Install packages from apt
# ----------------------------------------------------
sudo apt-get install -y \
    build-essential \
    procps \
    curl \
    file \
    git \
    eza \
    fastfetch \
    cmatrix \
    starship \
    zsh \
    fzf \
    dconf-cli \
    tmux \
    bat \
    fd-find \
    ripgrep \
    unzip \
    wget \
    libssl-dev \
    net-tools

# ----------------------------------------------------
# starship
# ----------------------------------------------------
curl -sS https://starship.rs/install.sh | sh

# ----------------------------------------------------
# Install nvm (Node Version Manager)
# ----------------------------------------------------
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

# ----------------------------------------------------
# Install Oh My Zsh
# ----------------------------------------------------
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# ----------------------------------------------------
# Install pnpm
# ----------------------------------------------------
# ----------------------------------------------------
# Install Bun
# ----------------------------------------------------
npm i -g pnpm bun

# ----------------------------------------------------
# Install Pyenv
# ----------------------------------------------------
curl -fsSL https://pyenv.run | bash

# ----------------------------------------------------
# Install Go
# ----------------------------------------------------
sudo apt install golang
export PATH=$PATH:/usr/local/go/bin

# ----------------------------------------------------
# Install television (tv)
# ----------------------------------------------------
curl -fsSL https://alexpasmantier.github.io/television/install.sh | bash

# ----------------------------------------------------
# Install yazi and dependencies
# ----------------------------------------------------
apt install ffmpeg 7zip jq poppler-utils fd-find ripgrep fzf zoxide imagemagick
unzip ./packages/yazi-x86_64-unknown-linux-gnu.zip -d ./packages/yazi-x86_64-unknown-linux-gnu
sudo cp ./packages/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
sudo cp ./packages/yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/

# ----------------------------------------------------
# Install Nerd Fonts
# ----------------------------------------------------
echo "Please install Nerd Fonts manually."
echo "You can download them from https://www.nerdfonts.com/font-downloads"
echo "and follow the instructions in the config_fonts/set.sh script."

echo "Installation finished."
echo "Please run the following scripts to set up the configuration files:"
echo "1. ./config_fonts/set.sh"
echo "2. ./config_gnome/config.sh"
echo "3. ./dotfiles/sync.sh"
