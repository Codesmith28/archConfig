#!/usr/bin/env bash
set -euo pipefail

# 1. Native hyprlauncher
if command -v hyprlauncher >/dev/null 2>&1; then
  if pgrep -x hyprlauncher >/dev/null 2>&1; then
    exec hyprlauncher -t
  else
    exec hyprlauncher
  fi
fi

# 2. Native hyprland-run (hyprland-guiutils runner)
if command -v hyprland-run >/dev/null 2>&1; then
  exec hyprland-run
fi

# 3. Fallback: Rofi apps launcher
if [[ -x "$HOME/.config/hypr/scripts/rofi-menu.sh" ]]; then
  exec "$HOME/.config/hypr/scripts/rofi-menu.sh" drun "Apps" \
    -theme-str 'window { width: 24%; } @media ( max-width: 1500 ) { window { width: 29%; } } @media ( max-width: 1100 ) { window { width: 48%; } }' \
    -modi "drun,run,window" \
    -drun-display-format "{icon}  {name}" \
    -matching fuzzy \
    -sorting-method fzf
elif command -v rofi >/dev/null 2>&1; then
  exec rofi -show drun
fi
