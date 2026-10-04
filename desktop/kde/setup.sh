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
fi

# If on Fedora, ensure AppStream metadata & Discover PackageKit backend are configured
if [ -f /etc/fedora-release ]; then
    FEDORA_APPSTREAM="$SCRIPT_DIR/../../distros/fedora/optimizations/appstream/setup.sh"
    if [ -f "$FEDORA_APPSTREAM" ]; then
        echo "==> Configuring Fedora AppStream metadata & KDE Discover PackageKit backend..."
        bash "$FEDORA_APPSTREAM"
    fi
fi

echo "✅ KDE setup complete!"
