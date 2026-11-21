#!/usr/bin/env bash
# ==============================================================================
# Waybar Volume Module Click Handler
# ==============================================================================
# - Click: Open pavucontrol
# - Ctrl + Click: Toggle mute
# - Middle / Right Click: Toggle mute
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

toggle_mute() {
    if [[ -x "$SCRIPT_DIR/volume.sh" ]]; then
        "$SCRIPT_DIR/volume.sh" mute
    elif command -v wpctl >/dev/null 2>&1; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-sink-mute @DEFAULT_SINK@ toggle
    elif command -v pamixer >/dev/null 2>&1; then
        pamixer -t
    fi
}

open_mixer() {
    if command -v pavucontrol >/dev/null 2>&1; then
        # If pavucontrol is already running, bring it to front via hyprctl or launch
        if pgrep -x pavucontrol >/dev/null 2>&1 && command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch focuswindow "class:^(pavucontrol|org.pulseaudio.pavucontrol)$" >/dev/null 2>&1 || exec pavucontrol &
        else
            exec pavucontrol &
        fi
    elif command -v org.pulseaudio.pavucontrol >/dev/null 2>&1; then
        exec org.pulseaudio.pavucontrol &
    elif command -v pavucontrol-qt >/dev/null 2>&1; then
        exec pavucontrol-qt &
    elif command -v pulsemixer >/dev/null 2>&1; then
        if command -v ghostty >/dev/null 2>&1; then
            exec ghostty --class=small_float --title=pulsemixer -e pulsemixer &
        else
            exec x-terminal-emulator -e pulsemixer &
        fi
    elif command -v alsamixer >/dev/null 2>&1; then
        if command -v ghostty >/dev/null 2>&1; then
            exec ghostty --class=small_float --title=alsamixer -e alsamixer &
        else
            exec x-terminal-emulator -e alsamixer &
        fi
    fi
}

ACTION="${1:-click}"

case "$ACTION" in
    mute|toggle-mute)
        toggle_mute
        exit 0
        ;;
    mixer|pavucontrol)
        open_mixer
        exit 0
        ;;
    click)
        # Check if Control key is currently held down
        IS_CTRL_HELD=false
        if command -v python3 >/dev/null 2>&1; then
            if python3 -c "import gi, sys; gi.require_version('Gdk', '3.0'); from gi.repository import Gdk; Gdk.init([]); disp = Gdk.Display.get_default(); sys.exit(0 if (disp and (Gdk.Keymap.get_for_display(disp).get_modifier_state() & 4)) else 1)" 2>/dev/null; then
                IS_CTRL_HELD=true
            fi
        fi

        if [[ "$IS_CTRL_HELD" == "true" ]]; then
            toggle_mute
        else
            open_mixer
        fi
        exit 0
        ;;
    *)
        open_mixer
        exit 0
        ;;
esac
