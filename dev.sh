cat <<"EOF"
     _            _____            
  __| | _____   _| ____|_ ____   __
 / _` |/ _ \ \ / /  _| | '_ \ \ / /
| (_| |  __/\ V /| |___| | | \ V / 
 \__,_|\___| \_/ |_____|_| |_|\_/  
                                   

EOF

#!/bin/bash

# Install Git and configure authentication
read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email

sudo pacman -Syu --noconfirm git
git config --global user.name "$git_username"
git config --global user.email "$git_email"

# Install GitHub CLI
sudo pacman -Syu --noconfirm github-cli

# Install Node Version Manager (NVM)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc

# Install latest LTS version of Node.js
nvm install --lts

# Install npm, pnpm, and Yarn
npm install -g pnpm yarn

# Install Bun
npm install -g bun

echo "Development environment setup complete!"