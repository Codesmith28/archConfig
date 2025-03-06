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
    local script_name
    script_name=$(basename "$script_path")

    if [[ -f "$script_path" ]]; then
        chmod +x "$script_path"  # Ensure script is executable
        read -p "Do you want to run $script_name? (Y/n): " choice
        choice=${choice:-y}  # Default to "y" if the user presses Enter
        case "$choice" in
            y|Y)
                echo "Running $script_name..."
                "$script_path"
                ;;
            n|N)
                echo "Skipping $script_name."
                ;;
            *)
                echo "Invalid choice. Running $script_name by default."
                "$script_path"
                ;;
        esac
    else
        echo "Error: $script_name does not exist. Skipping."
    fi
}

# Sequentially prompt and run other scripts
for script in "${scripts[@]}"; do
    run_script "$script"
done

echo "All scripts processed and packages installed!"
