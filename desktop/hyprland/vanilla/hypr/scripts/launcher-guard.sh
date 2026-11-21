#!/usr/bin/env bash
# ==============================================================================
# Single Launcher Instance & Toggle Controller
# Prevents multiple launchers from stacking on top of each other
# ==============================================================================

guard_launcher() {
    local launcher_id="$1"
    local state_file="$HOME/.cache/active_launcher"
    mkdir -p "$HOME/.cache"

    local is_running=false
    if pkill -0 -x wofi 2>/dev/null || pkill -0 -x rofi 2>/dev/null || pgrep -x hyprlauncher >/dev/null 2>&1; then
        is_running=true
    fi

    if [ "$is_running" = true ]; then
        local active_id=""
        if [ -f "$state_file" ]; then
            active_id="$(cat "$state_file" 2>/dev/null || true)"
        fi

        # Dismiss all running launcher instances
        pkill -x wofi 2>/dev/null || true
        pkill -x rofi 2>/dev/null || true
        if pgrep -x hyprlauncher >/dev/null 2>&1; then
            hyprlauncher -t 2>/dev/null || true
        fi
        rm -f "$state_file"

        # If the same launcher was triggered, toggle-to-close and exit cleanly
        if [ "$active_id" = "$launcher_id" ]; then
            exit 0
        fi

        # Brief settle time to avoid Wayland surface collision
        sleep 0.05
    fi

    echo "$launcher_id" > "$state_file"
}
