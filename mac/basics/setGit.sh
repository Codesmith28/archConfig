#!/bin/bash

cat <<"EOF"
  ____ _ _
 / ___(_) |_
| |   _| | __|
| |_| | | |_
 \____|_|\__|

EOF

echo "--- Strict Multi-Profile Git Setup ---"

# 1. Collect Profile Label (e.g., work, personal)
read -rp "Enter a label for this profile (e.g., work, personal): " LABEL
LABEL=$(echo "$LABEL" | tr '[:upper:]' '[:lower:]') # Force lowercase

# 2. Collect Identity Details
read -rp "Enter Git Name for $LABEL: " GIT_NAME
read -rp "Enter Git Email for $LABEL: " GIT_EMAIL

# 3. Define and Create Paths
TARGET_DIR="$HOME/$LABEL"
mkdir -p "$TARGET_DIR"

# Place the specific config INSIDE the target directory to prevent home folder clutter
CONFIG_FILE="$TARGET_DIR/.gitconfig-$LABEL"
SSH_KEY_PATH="$HOME/.ssh/id_$LABEL"

# 4. Create the Profile-Specific Git Config
# Included '-o IdentitiesOnly=yes' to ensure strict isolation per execution
echo "[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
[core]
    sshCommand = \"ssh -i $SSH_KEY_PATH -o IdentitiesOnly=yes\"" >"$CONFIG_FILE"

# 5. Add Conditional Include to Global Config
git config --global "includeIf.gitdir:$TARGET_DIR/".path "$CONFIG_FILE"

echo "Git config created and linked to $TARGET_DIR"

# 6. Setup SSH Key (Upgraded to ed25519)
if [ -f "$SSH_KEY_PATH" ]; then
    echo "SSH key for $LABEL already exists. Skipping generation."
else
    echo "Generating ed25519 SSH key for $LABEL..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N ""
fi

# NOTE: We specifically DO NOT add the key to ssh-agent or the Apple keychain here.
# Relying entirely on core.sshCommand prevents global credential leakage.

# 7. Output Public Key for GitHub
echo -e "\n------------------------------------------------------------"
echo "SETUP SUCCESSFUL"
echo "Profile: $LABEL"
echo "Directory: $TARGET_DIR"
echo "Config File: $CONFIG_FILE"
echo "SSH Key: $SSH_KEY_PATH"
echo "------------------------------------------------------------"
echo "Copy this Public Key to your GitHub account ($GIT_EMAIL):"
cat "${SSH_KEY_PATH}.pub"
echo "------------------------------------------------------------"

# 8. GitHub CLI Login (Optional)
read -rp "Do you want to log into GitHub CLI for this profile? (y/n): " LOGIN_GH
if [[ "$LOGIN_GH" =~ ^[Yy]$ ]]; then
    gh auth login
    gh config set git_protocol ssh
fi

echo -e "\nAll set! Any project inside $TARGET_DIR will strictly use your $LABEL credentials."
