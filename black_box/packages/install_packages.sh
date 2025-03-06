#!/bin/bash

cat << "EOF"
 _           _        _ _
(_)_ __  ___| |_ __ _| | | ___ _ __
| | '_ \/ __| __/ _` | | |/ _ \ '__|
| | | | \__ \ || (_| | | |  __/ |
|_|_| |_|___/\__\__,_|_|_|\___|_|

EOF

# Get the directory of this script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Check if yay is installed or not
if ! command -v yay &> /dev/null; then
    echo "yay is not installed. Installing yay..."
    sudo pacman -S yay --noconfirm
fi

# List of other scripts to execute sequentially (using full paths)
scripts=(
    "$SCRIPT_DIR/system_tools.sh"
    "$SCRIPT_DIR/general_packages.sh"
    "$SCRIPT_DIR/fonts.sh"
    "$SCRIPT_DIR/file_manager.sh"
    "$SCRIPT_DIR/multi_media.sh"
    "$SCRIPT_DIR/additional_tools.sh"
    "$SCRIPT_DIR/dev_packages.sh"
    "$SCRIPT_DIR/utility_packages.sh"
    "$SCRIPT_DIR/gnome_gtk.sh"
    "$SCRIPT_DIR/hyprland_components.sh"
)

# Function to prompt and run a script
run_script() {
    local script_path="$1"
    if [[ -x "$script_path" ]]; then
        read -p "Do you want to run $(basename "$script_path")? (y/n): " choice
        case "$choice" in
            y|Y)
                echo "Running $(basename "$script_path")..."
                "$script_path"
                ;;
            n|N)
                echo "Skipping $(basename "$script_path")."
                ;;
            *)
                echo "Invalid choice. Skipping $(basename "$script_path")."
                ;;
        esac
    else
        echo "Error: $(basename "$script_path") is not executable or does not exist. Skipping."
    fi
}

# Sequentially prompt and run other scripts
for script in "${scripts[@]}"; do
    run_script "$script"
done

echo "All scripts processed and packages installed!"
