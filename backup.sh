#!/bin/bash

# Function to recursively update files
recursive_update() {
    local source="$1"
    local destination="$2"

    # Iterate through items in the source directory
    shopt -s dotglob
    for item in "$source"/*; do
        if [ -d "$item" ]; then
            # If item is a directory, recursively update contents
            local dest_dir="$destination/$(basename "$item")"
            if [ -d "$dest_dir" ]; then
                recursive_update "$item" "$dest_dir"
            fi
        elif [ -f "$item" ]; then
            # If item is a file, check if it exists in the destination
            if [ -e "$destination/$(basename "$item")" ]; then
                # If file exists in both source and destination, update it
                cp -f "$item" "$destination"
                echo "Updated $(basename "$item")"
            fi
        fi
    done
}

# Set the paths for the two folders
source_folder="$HOME"
destination_folder="$HOME/Downloads/arch-config"

# Check if both folders exist
if [ ! -d "$source_folder" ]; then
    echo "Source folder does not exist!"
    exit 1
fi

if [ ! -d "$destination_folder" ]; then
    echo "Destination folder does not exist!"
    exit 1
fi

# Call the function to recursively update files
recursive_update "$source_folder" "$destination_folder"

echo "Update process completed!"