#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << 'EOF'
Usage: cycle-power-mode.sh [--notify|--no-notify]

Cycles power profiles in this order:
  power-saver -> balanced -> performance -> power-saver
EOF
}

notify_enabled=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --notify)
            notify_enabled=true
            ;;
        --no-notify)
            notify_enabled=false
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

notify_user() {
    local message="$1"
    if [[ "$notify_enabled" == true ]] && command -v notify-send >/dev/null 2>&1; then
        notify-send -t 1500 "Power Profile" "$message"
    fi
}

if ! command -v powerprofilesctl >/dev/null 2>&1; then
    message="powerprofilesctl is required but was not found in PATH."
    echo "$message" >&2
    notify_user "$message"
    exit 127
fi

current_mode="$(powerprofilesctl get 2>/dev/null || true)"
if [[ -z "$current_mode" ]]; then
    message="Unable to read current power profile."
    echo "$message" >&2
    notify_user "$message"
    exit 1
fi

unknown_mode=""
case "$current_mode" in
    power-saver) next_mode="balanced" ;;
    balanced) next_mode="performance" ;;
    performance) next_mode="power-saver" ;;
    *)
        unknown_mode="$current_mode"
        next_mode="power-saver"
        ;;
esac

if ! powerprofilesctl set "$next_mode"; then
    message="Failed to switch power profile to: $next_mode"
    echo "$message" >&2
    notify_user "$message"
    exit 1
fi

notification="Switched to: $next_mode"
if [[ -n "$unknown_mode" ]]; then
    notification="Unknown current profile ($unknown_mode). Switched to: $next_mode"
fi

if command -v supergfxctl >/dev/null 2>&1; then
    if supergfx_mode="$(supergfxctl -g 2>/dev/null)"; then
        supergfx_mode="${supergfx_mode//$'\n'/ }"
        if [[ -n "$supergfx_mode" ]]; then
            notification="$notification | GPU: $supergfx_mode"
        fi
    fi
fi

notify_user "$notification"
echo "$notification"
