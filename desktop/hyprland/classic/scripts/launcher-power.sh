#!/usr/bin/env bash
set -euo pipefail

choice="$(printf '%s\n' \
  'Lock' \
  'Sleep' \
  'Logout' \
  'Restart' \
  'Shutdown' | "$HOME/.config/hypr/scripts/rofi-menu.sh" dmenu "Power" \
    -theme-str 'window { width: 24%; } @media ( max-width: 1500 ) { window { width: 29%; } } @media ( max-width: 1100 ) { window { width: 48%; } }')"

case "$choice" in
  Lock)
    if command -v hyprlock >/dev/null 2>&1; then
      exec hyprlock
    fi
    exec loginctl lock-session
    ;;
  Sleep)
    exec systemctl suspend
    ;;
  Logout)
    exec hyprctl dispatch exit
    ;;
  Restart)
    exec systemctl reboot
    ;;
  Shutdown)
    exec systemctl poweroff
    ;;
  *)
    exit 0
    ;;
esac