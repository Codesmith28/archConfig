cat <<"EOF"
     _             _               
 ___| |_ __ _ _ __| |_ _   _ _ __  
/ __| __/ _` | '__| __| | | | '_ \ 
\__ \ || (_| | |  | |_| |_| | |_) |
|___/\__\__,_|_|   \__|\__,_| .__/ 
                            |_|    

EOF

#!/bin/bash

# Set the startup script
echo "Setting the startup apps for arch linux..."
startup_dir=~/.config/systemd/user

mkdir -p $startup_dir

echo "Setting up discord startup script..."
cp discord.service $startup_dir
systemctl --user enable discord.service
systemctl --user start discord.service
echo "Discord startup script set!"

echo "Setting up slack startup script..."
cp slack.service $startup_dir
systemctl --user enable slack.service
systemctl --user start slack.service
echo "Slack startup script set!"