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
    for src_file in $(find "$source_folder" -type f ! -path "*/.git/*"); do
        relative_path="${src_file#$source_folder}"
        dest_file="$destination_folder/$relative_path"

        if [ ! -f "$dest_file" ]; then
            echo "Adding missing file: $relative_path"
            mkdir -p "$(dirname "$dest_file")"
            cp "$src_file" "$dest_file"
        else
            if ! cmp -s "$src_file" "$dest_file"; then
                echo "Replacing modified file: $relative_path"
                cp "$src_file" "$dest_file"
            fi
        fi
    done
}

sync_dotfiles
echo "Backup completed."
