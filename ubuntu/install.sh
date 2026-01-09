#!/bin/bash

# Installation script for Ubuntu
set -e

echo "Starting installation..."

# ----------------------------------------------------
# Update and Upgrade
# ----------------------------------------------------
sudo apt update -y
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
sudo apt update -y
sudo apt full-upgrade -y

# Zsh tooling (idempotent)
[ -d "${ZDOTDIR:-$HOME}/.antidote" ] ||
    git clone --depth=1 https://github.com/mattmc3/antidote.git \
        "${ZDOTDIR:-$HOME}/.antidote"

[ -d "$HOME/.zsh-defer" ] ||
    git clone https://github.com/romkatv/zsh-defer.git \
        "$HOME/.zsh-defer"

# ----------------------------------------------------
# Install packages from apt
# ----------------------------------------------------
sudo apt install -y \
    curl \
    build-essential \
    procps \
    file \
    git \
    eza \
    fastfetch \
    cmatrix \
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
    net-tools \
    gnome-calculator \
    xournalpp \
    cheese \
    glow \
    ffmpeg \
    p7zip-full \
    p7zip-rar \
    jq \
    poppler-utils \
    zoxide \
    imagemagick

# Symlink batcat -> bat and fdfind -> fd
sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd

# ----------------------------------------------------
# starship prompt
# ----------------------------------------------------
curl -sS https://starship.rs/install.sh | sh

# ----------------------------------------------------
# Install nvm (Node Version Manager)
# ----------------------------------------------------
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

# ----------------------------------------------------
# Install Bun
# ----------------------------------------------------
curl -fsSL https://bun.sh/install | bash

# ----------------------------------------------------
# Install Pyenv
# ----------------------------------------------------
curl -fsSL https://pyenv.run | bash

# ----------------------------------------------------
# Install Go
# ----------------------------------------------------
sudo apt install -y golang

# ----------------------------------------------------
# Install Rust
# ----------------------------------------------------
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# ----------------------------------------------------
# Install television (tv)
# ----------------------------------------------------
curl -fsSL https://alexpasmantier.github.io/television/install.sh | bash

# ----------------------------------------------------
# Install Yazi (manual step advisory)
# ----------------------------------------------------
echo "Yazi binary not included."
echo "Download from: https://github.com/sxyazi/yazi/releases"
echo "Then copy binaries:"
echo "sudo cp yazi /usr/local/bin/"
echo "sudo cp ya /usr/local/bin/"
echo ""
