#!/bin/bash

# Paths
wal_colors_file="$HOME/.cache/wal/colors"
rofi_colors_file="$HOME/.cache/wal/colors-rofi-pywal.rasi"
hyprland_colors_file="$HOME/.cache/wal/colors-hyprland.conf"

# Check if the Pywal colors file exists
if [ ! -f "$wal_colors_file" ]; then
    echo "Error: Pywal colors file not found at $wal_colors_file."
    exit 1
fi

# Read colors from Pywal file
mapfile -t colors < "$wal_colors_file"

# Ensure there are at least 16 colors
if [ "${#colors[@]}" -lt 16 ]; then
    echo "Error: Pywal colors file does not contain enough colors."
    exit 1
fi

# Generate Rofi colors file
cat > "$rofi_colors_file" <<EOL
* {
    background: rgba(0,0,1,0.5);
    foreground: ${colors[7]};
    color0:     ${colors[0]};
    color1:     ${colors[1]};
    color2:     ${colors[2]};
    color3:     ${colors[3]};
    color4:     ${colors[4]};
    color5:     ${colors[5]};
    color6:     ${colors[6]};
    color7:     ${colors[7]};
    color8:     ${colors[8]};
    color9:     ${colors[9]};
    color10:    ${colors[10]};
    color11:    ${colors[11]};
    color12:    ${colors[12]};
    color13:    ${colors[13]};
    color14:    ${colors[14]};
    color15:    ${colors[15]};
}
EOL

echo "Updated Rofi colors: $rofi_colors_file"

# Generate Hyprland colors file
cat > "$hyprland_colors_file" <<EOL
\$background = rgb(${colors[0]:1})
\$foreground = rgb(${colors[7]:1})
\$color0 = rgb(${colors[0]:1})
\$color1 = rgb(${colors[1]:1})
\$color2 = rgb(${colors[2]:1})
\$color3 = rgb(${colors[3]:1})
\$color4 = rgb(${colors[4]:1})
\$color5 = rgb(${colors[5]:1})
\$color6 = rgb(${colors[6]:1})
\$color7 = rgb(${colors[7]:1})
\$color8 = rgb(${colors[8]:1})
\$color9 = rgb(${colors[9]:1})
\$color10 = rgb(${colors[10]:1})
\$color11 = rgb(${colors[11]:1})
\$color12 = rgb(${colors[12]:1})
\$color13 = rgb(${colors[13]:1})
\$color14 = rgb(${colors[14]:1})
\$color15 = rgb(${colors[15]:1})
EOL

echo "Updated Hyprland colors: $hyprland_colors_file"

# Reload Hyprland if necessary
if command -v hyprctl &> /dev/null; then
    hyprctl reload
    echo "Hyprland reloaded."
fi

echo "Color update complete!"
