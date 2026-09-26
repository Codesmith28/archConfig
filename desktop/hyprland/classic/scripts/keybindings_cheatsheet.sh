#!/bin/bash

# A script to generate the keybindings cheatsheet
config_file="$HOME/.config/hypr/conf.d/keybindings.conf"

generate_cheatsheet() {
    echo -e "\n=== HYPRLAND KEYBINDINGS CHEATSHEET ===\n"

    grep -E '^(bind|bindm|bindl|bindel)\s*=' "$config_file" | \
    sed -E 's/^(bind|bindm|bindl|bindel)\s*=\s*//' | \
    sed 's/\$mainMod/SUPER/g' | \
    awk -F',' '{
        mod = $1
        key = $2
        action = $3
        target = $4
        
        # Strip leading/trailing whitespaces
        gsub(/^[ \t]+|[ \t]+$/, "", mod)
        gsub(/^[ \t]+|[ \t]+$/, "", key)
        gsub(/^[ \t]+|[ \t]+$/, "", action)
        gsub(/^[ \t]+|[ \t]+$/, "", target)
        
        if (target != "") {
            printf "%s + %s\t=> %s %s\n", mod, key, action, target
        } else {
            printf "%s + %s\t=> %s\n", mod, key, action
        }
    }' | column -t -s $'\t'

    echo -e "\n(Press 'q' to close, arrows/vim keys to scroll)"
}

# Generate and pipe to less (with -R for raw characters and -K to enable quitting with q, +G to go to end, etc. we just use less)
# We export LESS to ensure less does not immediately exit, and clears the screen nicely
LESS="-R -c" generate_cheatsheet | less