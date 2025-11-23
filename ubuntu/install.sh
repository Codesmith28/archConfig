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
# Install Oh My Zsh
# Avoid auto-shell-switch while running script
# ----------------------------------------------------
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Ensure ZSH_CUSTOM is set
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Add Oh My Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || true

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
echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.bashrc

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

# ----------------------------------------------------
# Install Nerd Fonts reminder
# ----------------------------------------------------
echo "Please install Nerd Fonts manually."
echo "https://www.nerdfonts.com/font-downloads"
echo "Then run ./config_fonts/set.sh after installation."
echo ""

# ----------------------------------------------------
# Done!
# ----------------------------------------------------
echo "Installation finished successfully!"
echo "Next steps:"
echo "1. Run: ./config_fonts/set.sh"
echo "2. Run: ./config_gnome/config.sh"
echo "3. Run: ./dotfiles/sync.sh"
echo ""
echo "Restart terminal to apply shell changes."
