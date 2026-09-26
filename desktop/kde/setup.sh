#!/usr/bin/env bash
# desktop/kde/setup.sh - Apply KDE Plasma custom shortcuts and keybindings
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KDE_SHORTCUTS="$SCRIPT_DIR/keyboardscs.kksrc"

echo "==> Configuring KDE Plasma Shortcuts..."

if [ -f "$KDE_SHORTCUTS" ]; then
    DEST_DIR="$HOME/.config/kxmlgui5"
    mkdir -p "$DEST_DIR"
    cp "$KDE_SHORTCUTS" "$DEST_DIR/keyboardscs.kksrc"
    
    # In Plasma, shortcut schemes can also be loaded via kwriteconfig
    echo "Shortcuts copied to $DEST_DIR/keyboardscs.kksrc"
    echo "You can apply this scheme via: System Settings -> Shortcuts -> Manage Shortcuts -> Import Scheme."
fi

echo "✅ KDE setup complete!"
