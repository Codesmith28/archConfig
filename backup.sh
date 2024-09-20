#!/bin/bash

cat <<"EOF"
 ____             _
| __ )  __ _  ___| | ___   _ _ __
|  _ \ / _` |/ __| |/ / | | | '_ \
| |_) | (_| | (__|   <| |_| | |_) |
|____/ \__,_|\___|_|\_\\__,_| .__/
                            |_|

EOF

source_folder="$HOME/dotfiles/"
destination_folder="$HOME/Downloads/archConfig/dotfiles"

sync_dotfiles() {
    find "$source_folder" ! -path "*/.git/*" | while IFS= read -r src_item; do
        relative_path="${src_item#$source_folder}"
        dest_item="$destination_folder/$relative_path"

        if [ -d "$src_item" ]; then
            if [ ! -d "$dest_item" ]; then
                echo "Adding missing directory: $relative_path"
                mkdir -p "$dest_item"
            fi
        elif [ -f "$src_item" ]; then
            if [ ! -f "$dest_item" ]; then
                echo "Adding missing file: $relative_path"
                cp "$src_item" "$dest_item"
            else
                if ! cmp -s "$src_item" "$dest_item"; then
                    echo "Replacing modified file: $relative_path"
                    cp "$src_item" "$dest_item"
                fi
            fi
        fi
    done
}

sync_dotfiles
echo "Backup completed."
