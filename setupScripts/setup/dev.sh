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
    "visual-studio-code-bin"
    "neovim"
    "distrobox"
    "clang"
    "fzf"
    "zsh"
    "github-cli"
    "bat"
    "github-cli"
    "lazygit"
)

# -------------------------------------------------------
# Install packages using yay
# -------------------------------------------------------

for package in "${packages[@]}"; do
    if yay -Qi "$package" &> /dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package..."
        yay -S --noconfirm "$package"
    fi
done
echo "All required packages are installed!"

# -------------------------------------------------------
#  Configure git and GitHub CLI
# -------------------------------------------------------

echo "Configuring git and GitHub CLI..."
read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email
git config --global user.name "$git_username"
git config --global user.email "$git_email"

# -------------------------------------------------------
# Setting up github cli:
# -------------------------------------------------------

gh auth login
sudo gh extension install github/copilot

# -------------------------------------------------------
# remove any preconfigured zsh configuration
# -------------------------------------------------------

rm -rf ~/.oh-my-zsh
# installing oh-my-zsh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# installing powerlevel10k for oh my zsh:
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# -------------------------------------------------------
# installing zsh-autosuggestions and zsh-syntax-highlighting:
# -------------------------------------------------------

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# -------------------------------------------------------
# Install Node Version Manager (NVM)
# -------------------------------------------------------

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc

# -------------------------------------------------------
# Install latest LTS version of Node.js
# -------------------------------------------------------

nvm install --lts

# -------------------------------------------------------
# Install npm, pnpm, and Yarn
# -------------------------------------------------------

sudo npm install -g yarn pnpm typescript ts-node bun

echo "Development environment setup complete!"
