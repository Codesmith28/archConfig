#!/bin/bash

cat <<"EOF"
  ____ _ _
 / ___(_) |_
| |   _| | __|
| |_| | | |_
 \____|_|\__|

EOF

echo "--- Individual Git Profile Setup (Enhanced for SSH) ---"

# 1. Collect Profile Label (e.g., work, personal)
read -rp "Enter a label for this profile (e.g., work, personal): " LABEL
LABEL=$(echo "$LABEL" | tr '[:upper:]' '[:lower:]') # Force lowercase

# 2. Collect Identity Details
read -rp "Enter Git Name for $LABEL: " GIT_NAME
read -rp "Enter Git Email for $LABEL: " GIT_EMAIL

# 3. Define and Create Paths
TARGET_DIR="$HOME/$LABEL"
mkdir -p "$TARGET_DIR"

CONFIG_FILE="$HOME/.gitconfig-$LABEL"
SSH_KEY_PATH="$HOME/.ssh/id_$LABEL"

# 4. Create the Profile-Specific Git Config (Updated with sshCommand)
# This forces git to use the specific key whenever you are inside TARGET_DIR
echo "[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
[core]
    sshCommand = \"ssh -i $SSH_KEY_PATH\"" >"$CONFIG_FILE"

# 5. Add Conditional Include to Global Config
git config --global "includeIf.gitdir:$TARGET_DIR/".path "$CONFIG_FILE"
git config --global pull.rebase false

echo "Git config created and linked to $TARGET_DIR"

# 6. Setup SSH Key
if [ -f "$SSH_KEY_PATH" ]; then
    echo "SSH key for $LABEL already exists. Skipping generation."
else
    echo "Generating SSH key for $LABEL..."
    ssh-keygen -t rsa -b 4096 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N ""
fi

# 7. Start SSH Agent and Add Key
eval "$(ssh-agent -s)"
# On Mac, we add it to the keychain so it persists after reboot
ssh-add --apple-use-keychain "$SSH_KEY_PATH"

# 8. Output Public Key for GitHub
echo -e "\n------------------------------------------------------------"
echo "SETUP SUCCESSFUL"
echo "Profile: $LABEL"
echo "Directory: $TARGET_DIR"
echo "SSH Key: $SSH_KEY_PATH"
echo "------------------------------------------------------------"
echo "Copy this Public Key to your GitHub account ($GIT_EMAIL):"
cat "${SSH_KEY_PATH}.pub"
echo "------------------------------------------------------------"

# 9. GitHub CLI Login
read -rp "Do you want to log into GitHub CLI for this profile? (y/n): " LOGIN_GH
if [[ "$LOGIN_GH" =~ ^[Yy]$ ]]; then
    gh auth login
    # Ensure gh uses SSH protocol
    gh config set git_protocol ssh
fi

echo -e "\nAll set! Any project inside $TARGET_DIR will use your $LABEL credentials."
echo "To clone the FIRST time into this folder, use:"
echo "git -c core.sshCommand=\"ssh -i $SSH_KEY_PATH\" clone <url>"
