#!/bin/bash

cat <<"EOF"
  ____          _   
 / ___|__ _ ___| |_ 
| |   / _` / __| __|
| |__| (_| \__ \ |_ 
 \____\__,_|___/\__|
                    

EOF

# Get the name of the main display
main_display="eDP-1"

# Function to prompt the user for action choice
prompt_action() {
    echo "Do you want to project or mirror the screen?"
    echo "1. Project (Extend)"
    echo "2. Mirror"
    read -p "Enter your choice (1 or 2): " choice
}

# Function to project the screen
project_screen() {
    # Loop through each connected display and extend the main display onto it
    for display in $connected_displays; do
        echo "Extending $main_display onto $display"
        xrandr --output $display --auto --right-of $main_display
    done
}

# Function to mirror the screen
mirror_screen() {
    # Loop through each connected display and mirror main display onto it
    for display in $connected_displays; do
        echo "Mirroring $main_display onto $display"
        xrandr --output $display --same-as $main_display
    done
}

# Get the list of connected displays excluding the main display
connected_displays=$(xrandr --listmonitors | grep -v "$main_display" | grep -oP '\b\w+-\d\b')

# Prompt the user for action choice
prompt_action

# Perform action based on user choice
case $choice in
    1) project_screen ;;
    2) mirror_screen ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
esac
