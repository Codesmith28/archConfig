#!/bin/bash

cat <<"EOF"
  ____ _ _
 / ___(_) |_
| |  _| | __|
| |_| | | |_
 \____|_|\__|

EOF

echo "Setting up Git and GitHub CLI..."

echo "Configuring git and GitHub CLI..."
read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email

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

# -------------------------------------------------------
# Setting up GitHub CLI
# -------------------------------------------------------

echo "Logging into GitHub via CLI..."
gh auth login

read -p "Do you want to install GitHub Copilot CLI? (y/n): " install_copilot
if [[ "$install_copilot" =~ ^[Yy]$ ]]; then
    sudo gh extension install github/copilot
fi

echo "Git environment setup successfully!"
