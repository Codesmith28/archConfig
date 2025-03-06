cat <<"EOF"
  ____ _ _
 / ___(_) |_
| |  _| | __|
| |_| | | |_
 \____|_|\__|

EOF

#!/bin/bash

echo "Setting up Git and GitHub CLI..."

packages=(
    "openssh"
    "git"
    "nodejs"
    "github-cli"
    "lazygit"
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
#  Configure git and GitHub CLI
# -------------------------------------------------------

echo "Configuring git and GitHub CLI..."
read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email

git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global pull.rebase false

# -------------------------------------------------------
# Setting up ssh keys:
# -------------------------------------------------------

ssh-keygen -t rsa -C "$git_email"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa.pub

# -------------------------------------------------------
# Setting up github cli:
# -------------------------------------------------------

gh auth login
sudo gh extension install github/copilot

echo "Git environment setup successfully!"
