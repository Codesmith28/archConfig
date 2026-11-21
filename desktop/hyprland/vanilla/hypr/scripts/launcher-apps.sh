#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/launcher-guard.sh" ]]; then
    source "$SCRIPT_DIR/launcher-guard.sh"
    guard_launcher "apps"
fi

# 1. Native hyprlauncher (if installed & available)
if command -v hyprlauncher >/dev/null 2>&1; then
  if pgrep -x hyprlauncher >/dev/null 2>&1; then
    exec hyprlauncher -t
  else
    exec hyprlauncher
  fi
fi

# 2. Modern Wayland Application Launcher: Wofi (drun mode)
if command -v wofi >/dev/null 2>&1; then
  wofi_conf=""
  wofi_style=""
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

  exec wofi --show drun "${WOFI_ARGS[@]}"
fi

# 3. Native hyprland-run (hyprland-guiutils runner)
if command -v hyprland-run >/dev/null 2>&1; then
  exec hyprland-run
fi

# 4. Fallback: Rofi app launcher
if [[ -z "${ROFI_CONFIG:-}" ]]; then
  if [[ -f "$HOME/.config/rofi/config.rasi" ]]; then
    export ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
  elif [[ -f "$(dirname "$0")/../../rofi/config.rasi" ]]; then
    export ROFI_CONFIG="$(cd "$(dirname "$0")/../../rofi" && pwd)/config.rasi"
  fi
fi

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
