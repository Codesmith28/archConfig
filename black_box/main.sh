#!/bin/bash

cat << "EOF"
               _                     _ _   _     ____  ___
  ___ ___   __| | ___  ___ _ __ ___ (_) |_| |__ |___ \( _ )
 / __/ _ \ / _` |/ _ \/ __| '_ ` _ \| | __| '_ \  __) / _ \
| (_| (_) | (_| |  __/\__ \ | | | | | | |_| | | |/ __/ (_) |
 \___\___/ \__,_|\___||___/_| |_| |_|_|\__|_| |_|_____\___/

EOF

# Get the directory of this script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Function to run a script with sudo if necessary
run_script() {
    local script_path="$1"
    local require_sudo="${2:-false}"

    if [ -f "$script_path" ]; then
        if [ "$require_sudo" = true ]; then
            echo "Running $script_path with sudo privileges..."
            sudo bash "$script_path"
        else
            echo "Running $script_path..."
            bash "$script_path"
        fi
    else
        echo "Error: Script not found -> $script_path"
    fi
}

# Install yay (only if not installed)
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    cd ~/Downloads || exit
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si
    cd ..
    rm -rf yay
    echo "yay installed."
else
    echo "yay is already installed."
fi

echo "Installing packages..."

# Define scripts with their paths
declare -A scripts=(
    ["$SCRIPT_DIR/config_pacman/setup.sh"]=true
    ["$SCRIPT_DIR/packages/install_packages.sh"]=true
    ["$SCRIPT_DIR/setup_git_github/setUpGit.sh"]=true
    ["$SCRIPT_DIR/config_gnome/config.sh"]=false
    ["$SCRIPT_DIR/link_dotfiles/link.sh"]=false
    ["$SCRIPT_DIR/setup_dev_env/setup.sh"]=true
    ["$SCRIPT_DIR/setup_docker_env/setDocker.sh"]=true
    ["$SCRIPT_DIR/setup_startup_apps/setup.sh"]=true
    ["$SCRIPT_DIR/setup_uni_wifi/setup.sh"]=true
    ["$SCRIPT_DIR/remap_keys/remap.sh"]=true
    ["$SCRIPT_DIR/config_grub/setup.sh"]=true
    ["$SCRIPT_DIR/configure_system_fonts/setup.sh"]=true
)

# Run each script
for script_path in "${!scripts[@]}"; do
    run_script "$script_path" "${scripts[$script_path]}"
done

echo "Setup complete."
