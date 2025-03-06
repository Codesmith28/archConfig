cat <<"EOF"
 _                      ___   _   _
(_) ___ ___  _ __  ___ ( _ ) | |_| |__   ___ _ __ ___   ___  ___
| |/ __/ _ \| '_ \/ __|/ _ \/\ __| '_ \ / _ \ '_ ` _ \ / _ \/ __|
| | (_| (_) | | | \__ \ (_>  < |_| | | |  __/ | | | | |  __/\__ \
|_|\___\___/|_| |_|___/\___/\/\__|_| |_|\___|_| |_| |_|\___||___/


EOF

#!/bin/bash

# Set the directory where you want to clone the repositories
base_dir="/$HOME/Downloads"

# Clone and install Colloid icon theme
cd "$base_dir"
git clone https://github.com/vinceliuice/Colloid-icon-theme.git
cd Colloid-icon-theme
./install.sh -s all
cd "$base_dir"

# Clone and install Orchis theme
cd "$base_dir"
git clone https://github.com/vinceliuice/Orchis-theme.git
cd Orchis-theme
./install.sh --tweaks -t all
cd "$base_dir"
