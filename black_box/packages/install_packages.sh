#!/bin/bash

cat << "EOF"
 _           _        _ _
(_)_ __  ___| |_ __ _| | | ___ _ __
| | '_ \/ __| __/ _` | | |/ _ \ '__|
| | | | \__ \ || (_| | | |  __/ |
|_|_| |_|___/\__\__,_|_|_|\___|_|

EOF

# check if yay is installed or not:
if ! command -v yay &> /dev/null; then
    echo "yay is not installed. Installing yay..."
    sudo pacman -S yay --noconfirm
fi

# List of other scripts to execute sequentially
scripts=(
    "system_tools.sh"
    "general_packages.sh"
    "fonts.sh"
    "file_manager.sh"
    "multi_media.sh"
    "additional_tools.sh"
    "dev_packages.sh"
    "utility_packages.sh"
    "gnome_gtk.sh"
    "hyprland_components.sh"
)

# Function to prompt and run a script
run_script() {
    local script_name="$1"
    if [[ -x "$script_name" ]]; then
        read -p "Do you want to run $script_name? (y/n): " choice
        case "$choice" in
            y|Y)
                echo "Running $script_name..."
                ./$script_name
                ;;
            n|N)
                echo "Skipping $script_name."
                ;;
            *)
                echo "Invalid choice. Skipping $script_name."
                ;;
        esac
    else
        echo "$script_name is not executable or does not exist. Skipping."
    fi
}

# Sequentially prompt and run other scripts
for script in "${scripts[@]}"; do
    run_script "$script"
done

echo "All scripts processed and packages installed!"
