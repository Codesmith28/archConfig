cat <<"EOF"
 _
| | _____ _   _ ___
| |/ / _ \ | | / __|
|   <  __/ |_| \__ \
|_|\_\___|\__, |___/
          |___/

EOF

#! /bin/bash
echo "Setting up ssh keys..."
# -------------------------------------------------------
# Generate a new SSH key
# -------------------------------------------------------

read -p "Enter your email: " email
ssh-keygen -t rsa -C "$email"

# -------------------------------------------------------
# Start the ssh-agent in the background
# -------------------------------------------------------

eval "$(ssh-agent -s)"

# -------------------------------------------------------
# Add your SSH private key to the ssh-agent
# -------------------------------------------------------

ssh-add ~/.ssh/id_rsa.pub
