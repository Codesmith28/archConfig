#!/bin/bash

cat <<"EOF"
  ____ _ _
 / ___(_) |_
| |  _| | __|
| |_| | | |_
 \____|_|\__|

EOF

echo "Setting up Git and GitHub CLI..."

packages=(
    "openssh-client"
    "git"
    "lazygit"
)

# -------------------------------------------------------
# Install packages using apt (Ubuntu)
# -------------------------------------------------------

sudo apt update -y

for package in "${packages[@]}"; do
    if dpkg -s "$package" &>/dev/null; then
        echo "$package is already installed. Skipping..."
    else
        echo "Installing $package..."
        sudo apt install -y "$package"
    fi
done

echo "All required packages are installed!"

# -------------------------------------------------------
# Configure git and GitHub CLI
# -------------------------------------------------------

echo "Configuring git..."
read -rp "Enter your Git username: " git_username
read -rp "Enter your Git email: " git_email

git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global pull.rebase false

# -------------------------------------------------------
# Setting up SSH keys
# -------------------------------------------------------

SSH_KEY_PATH="$HOME/.ssh/id_rsa"

if [ -f "$SSH_KEY_PATH" ]; then
    echo "SSH key already exists at $SSH_KEY_PATH. Skipping key generation."
else
    echo "Generating new SSH key..."
    ssh-keygen -t rsa -b 4096 -C "$git_email" -f "$SSH_KEY_PATH" -N ""
fi

eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH"

echo "Your SSH key has been added to the agent. Copy it to GitHub:"
echo "------------------------------------------------------------"
cat "$SSH_KEY_PATH.pub"
echo "------------------------------------------------------------"

echo "Git environment setup successfully!"
