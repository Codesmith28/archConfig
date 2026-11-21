#!/usr/bin/env bash
# ==============================================================================
# Hyprland Keybindings Cheatsheet Launcher
# ==============================================================================
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$script_dir/launcher-guard.sh" ]]; then
    source "$script_dir/launcher-guard.sh"
    guard_launcher "shortcuts"
fi

# Resolve Wofi config and style
wofi_conf=""
wofi_style=""
for c in "$HOME/.config/wofi/config" \
         "$script_dir/../../wofi/config"; do
    if [[ -f "$c" ]]; then
        wofi_conf="$c"
        break
    fi
done

for s in "$HOME/.config/wofi/style.css" \
         "$script_dir/../../wofi/style.css"; do
    if [[ -f "$s" ]]; then
        wofi_style="$s"
        break
    fi
done

WOFI_ARGS=()
[[ -n "$wofi_conf" ]] && WOFI_ARGS+=(--conf "$wofi_conf")
[[ -n "$wofi_style" ]] && WOFI_ARGS+=(--style "$wofi_style")

shortcuts="󰌌  SUPER + Return                 ➔  Launch Terminal (Ghostty / GNOME)
󰌌  SUPER + Shift + Return           ➔  Launch Large Floating Terminal
󰌌  SUPER + Space / D               ➔  Open Application Launcher (Wofi)
󰌌  SUPER + / (or ?)                 ➔  Open Keybindings Cheatsheet
󰌌  SUPER + E                       ➔  Open File Manager (Nautilus)
󰌌  SUPER + B                       ➔  Open Web Browser
󰌌  SUPER + V                       ➔  Open Clipboard History
󰌌  SUPER + Ctrl + B                ➔  Open Bluetooth Manager
󰌌  SUPER + Ctrl + V                ➔  Open Volume Control (Pavucontrol)
󰌌  SUPER + Period                  ➔  Open Emoji Picker
󰌌  SUPER + W                       ➔  Open Wallpaper Picker
󰌌  SUPER + Tab                     ➔  Switch Active Window (Window Switcher)
󰌌  SUPER + Alt + T                 ➔  Select Theme (Catppuccin / Tokyo Night / Monochrome)
󰌌  SUPER + Shift + B               ➔  Reload Waybar Status Bar
󰌌  SUPER + Alt + B                 ➔  Toggle / Kill Waybar Status Bar
󰌌  SUPER + L                       ➔  Lock Screen (Hyprlock / Loginctl)
󰌌  SUPER + Escape                  ➔  Power Menu (Sleep, Reboot, Poweroff)
󰌌  SUPER + Q / Alt + F4            ➔  Close / Kill Active Window
󰌌  SUPER + C                       ➔  Center Active Window
󰌌  SUPER + T                       ➔  Toggle Window Floating Mode
󰌌  SUPER + Ctrl + F                ➔  Resize Window to Small Float (680x440)
󰌌  SUPER + Alt + F                 ➔  Resize Window to Medium Float (960x600)
󰌌  SUPER + Shift + F               ➔  Cycle Float Sizing (Small / Medium / Big)
󰌌  SUPER + F / F11                 ➔  Toggle Fullscreen Mode
󰌌  SUPER + P                       ➔  Toggle Pseudo Tiling Mode
󰌌  SUPER + J                       ➔  Toggle Dwindle Split Direction
󰌌  SUPER + Arrow Keys              ➔  Focus Window (Left / Right / Up / Down)
󰌌  SUPER + Shift + Arrow Keys      ➔  Resize Active Window
󰌌  SUPER + Ctrl + Shift + Arrows   ➔  Move Active Window
󰌌  SUPER + Mouse Left Drag         ➔  Move Floating Window
󰌌  SUPER + Mouse Right Drag        ➔  Resize Window
󰌌  SUPER + 1 .. 9, 0               ➔  Switch to Workspace 1..10
󰌌  SUPER + Shift + 1 .. 0          ➔  Move Active Window to Workspace 1..10
󰌌  SUPER + U / SUPER + S           ➔  Toggle Special Workspace (Magic Scratchpad)
󰌌  SUPER + Shift + U / SUPER + M   ➔  Move Active Window to Special Workspace
󰌌  SUPER + Mouse Scroll            ➔  Cycle Workspaces (Next / Previous)
󰌌  Print / SUPER + Shift + S       ➔  Take Region Screenshot (Grim + Slurp)
󰌌  SUPER + Print                   ➔  Take Fullscreen Screenshot (Grim)
󰌌  SUPER + Shift + W               ➔  Take Window Screenshot (Grim + Slurp)
󰌌  SUPER + Shift + A               ➔  Take Fullscreen Screenshot (Grim)
󰌌  SUPER + Shift + E               ➔  Take Screenshot & Annotate (Swappy)
󰌌  Keyboard Power / Sleep Key      ➔  Suspend System to RAM
󰌌  Volume Keys (Up/Down/Mute)      ➔  Adjust / Toggle Audio Volume
󰌌  Brightness Keys (Up/Down)       ➔  Adjust Display Brightness"

if command -v wofi >/dev/null 2>&1; then
    printf "%s\n" "$shortcuts" | wofi --dmenu -p "Hyprland Shortcuts..." --width=860 --lines=16 --insensitive --hide-scroll "${WOFI_ARGS[@]}" >/dev/null 2>&1 || true
    exit 0
fi

# Fallback: terminal viewer with less
if [ -t 1 ]; then
    echo -e "\n=== HYPRLAND KEYBINDINGS CHEATSHEET ===\n"
    printf "%s\n" "$shortcuts"
    echo -e "\n(Press 'q' to close, arrows/vim keys to scroll)"
else
    LESS="-R -c" printf "%s\n" "$shortcuts" | less || true
fi
