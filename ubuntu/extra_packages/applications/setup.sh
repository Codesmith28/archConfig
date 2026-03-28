#!/bin/bash

set -euo pipefail

# Check if any .desktop files exist
shopt -s nullglob
files=(*.desktop)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "No .desktop files found in the current directory."
    exit 1
fi

echo "Moving the following files to /usr/share/applications/:"
for f in "${files[@]}"; do
    echo "  $f"
done
echo ""

echo "Reminder: Please place your corresponding .AppImage files in /opt/ directory."
echo ""

# Copy files with sudo
sudo cp "${files[@]}" /usr/share/applications/

echo "Done."
