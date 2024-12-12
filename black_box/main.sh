#!/bin/bash

cat << "EOF"
               _                     _ _   _     ____  ___
  ___ ___   __| | ___  ___ _ __ ___ (_) |_| |__ |___ \( _ )
 / __/ _ \ / _` |/ _ \/ __| '_ ` _ \| | __| '_ \  __) / _ \
| (_| (_) | (_| |  __/\__ \ | | | | | | |_| | | |/ __/ (_) |
 \___\___/ \__,_|\___||___/_| |_| |_|_|\__|_| |_|_____\___/

EOF

# Function to run a script with sudo if necessary
run_script() {
    local script_path="$1"
    local require_sudo="${2:-false}"

    if [ "$require_sudo" = true ]; then
        echo "Running $script_path with sudo privileges..."
        sudo bash "$script_path"
    else
        echo "Running $script_path..."
        bash "$script_path"
    fi
}

if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be run with sudo. Rerunning with sudo..."
    exec sudo bash "$0" "$@"
fi

declare -A scripts=(
    ["./setup_git_github/setUpGit.sh"]=true
    ["./config_pacman/setup.sh"]=true
    ["./packages/install_packages.sh"]=true
    ["./link_dotfiles/link.sh"]=false
    ["./setup_dev_env/setup.sh"]=true
    ["./setup_docker_env/setDocker.sh"]=true
    ["./setup_startup_apps/setup.sh"]=false
    ["./setup_uni_wifi/setup.sh"]=true
    ["./remap_keys/remap.sh"]=true
    ["./config_grub/setup.sh"]=true
    ["./configure_system_fonts/setup.sh"]=true
)

for script_path in "${!scripts[@]}"; do
    run_script "$script_path" "${scripts[$script_path]}"
done
