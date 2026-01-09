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
    ffmpeg \
    p7zip-full \
    p7zip-rar \
    jq \
    poppler-utils \
    zoxide \
    imagemagick

# 1. Create the local bin directory if it doesn't exist
mkdir -p ~/.local/bin
# 2. Download and extract directly into that directory
wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz -C ~/.local/bin
# 3. Ensure it is executable (tar usually preserves this, but just in case)
chmod +x ~/.local/bin/eza

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
