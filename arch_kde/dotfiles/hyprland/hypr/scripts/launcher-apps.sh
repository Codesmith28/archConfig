#!/usr/bin/env bash
set -euo pipefail

exec "$HOME/.config/hypr/scripts/rofi-menu.sh" drun "Apps" \
  -theme-str 'window { width: 24%; } @media ( max-width: 1500 ) { window { width: 29%; } } @media ( max-width: 1100 ) { window { width: 48%; } }' \
  -modi "drun,run,window" \
  -drun-display-format "{icon}  {name}" \
  -matching fuzzy \
  -sorting-method fzf
