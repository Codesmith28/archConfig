#!/usr/bin/env bash
set -euo pipefail

# rofi-emoji returns entries like: 😀 grinning face
selection="$("$HOME/.config/hypr/scripts/rofi-menu.sh" emoji "Emoji" -theme-str 'window { width: 24%; } @media ( max-width: 1500 ) { window { width: 29%; } } @media ( max-width: 1100 ) { window { width: 48%; } }' -matching fuzzy || true)"
[[ -z "$selection" ]] && exit 0

emoji="$(printf '%s\n' "$selection" | sed -E 's/^([^[:space:]]+).*/\1/')"
printf '%s' "$emoji" | wl-copy

if command -v notify-send >/dev/null 2>&1; then
  notify-send -a "Rofi Emoji" "Copied to clipboard" "$emoji"
fi
