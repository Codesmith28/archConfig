 cat <<"EOF"
     _            _____
  __| | _____   _| ____|_ ____   __
 / _` |/ _ \ \ / /  _| | '_ \ \ / /
| (_| |  __/\ V /| |___| | | \ V /
 \__,_|\___| \_/ |_____|_| |_|\_/


EOF
#! /bin/bash

echo "Setting up the development environment..."

# -------------------------------------------------------
# install important packages for development:
# -------------------------------------------------------

packages=(
    "vim"
    "visual-studio-code-bin"
    "neovim"
    "distrobox"
    "mongodb-compass"
    "clang"
    "go"
    "fzf"
    "zsh"
    "bat"
    "nvm"
    "python-pipx"
)

# ------------------------------w-------------------------
# Install packages using yay
# -------------------------------------------------------

for package in "${packages[@]}"; do
    if yay -Qi "$package" &> /dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package..."
        sudo yay -S --noconfirm "$package"
    fi
done
echo "All required packages are installed!"

# -------------------------------------------------------
# ensure path of pipx:
# -------------------------------------------------------

pipx ensurepath

# -------------------------------------------------------
# Install latest LTS version of Node.js
# -------------------------------------------------------

nvm install --lts

# -------------------------------------------------------
# Install npm, pnpm, and Yarn
# -------------------------------------------------------

sudo npm install -g yarn pnpm typescript ts-node bun

# -------------------------------------------------------
# remove any preconfigured zsh configuration
# -------------------------------------------------------

# remove any preconfigured zsh configuration
rm -rf ~/.oh-my-zsh

# installing oh-my-zsh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# installing powerlevel10k for oh my zsh:
# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# -------------------------------------------------------
# installing zsh-autosuggestions and zsh-syntax-highlighting:
# -------------------------------------------------------

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting


echo "Development environment setup complete!"
