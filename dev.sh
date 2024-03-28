cat <<"EOF"
     _            _____
  __| | _____   _| ____|_ ____   __
 / _` |/ _ \ \ / /  _| | '_ \ \ / /
| (_| |  __/\ V /| |___| | | \ V /
 \__,_|\___| \_/ |_____|_| |_|\_/


EOF

#!/bin/bash

# Plugins for zsh: zsh-autosuggestions and zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

# Install Git and configure authentication
read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email

sudo pacman -Syu --noconfirm git
git config --global user.name "$git_username"
git config --global user.email "$git_email"

# Install GitHub CLI
sudo pacman -Syu --noconfirm github-cli
sudo gh extension install github/copilot

# Install Node Version Manager (NVM)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc

# Install latest LTS version of Node.js
nvm install --lts

# Install npm, pnpm, and Yarn
sudo npm install -g yarn pnpm typescript ts-node bun

echo "Development environment setup complete!"
