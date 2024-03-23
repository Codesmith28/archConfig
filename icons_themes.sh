cat <<"EOF"
 _                      ___   _   _                              
(_) ___ ___  _ __  ___ ( _ ) | |_| |__   ___ _ __ ___   ___  ___ 
| |/ __/ _ \| '_ \/ __|/ _ \/\ __| '_ \ / _ \ '_ ` _ \ / _ \/ __|
| | (_| (_) | | | \__ \ (_>  < |_| | | |  __/ | | | | |  __/\__ \
|_|\___\___/|_| |_|___/\___/\/\__|_| |_|\___|_| |_| |_|\___||___/
                                                                 

EOF

#!/bin/bash

# Clone and install Colloid icon theme
git clone https://github.com/vinceliuice/Colloid-icon-theme.git
cd Colloid-icon-theme
./install.sh -s all
cd ..

# Clone and install Orchis theme
git clone https://github.com/vinceliuice/Orchis-theme.git
cd Orchis-theme
./install.sh --tweaks black -t red
cd ..
