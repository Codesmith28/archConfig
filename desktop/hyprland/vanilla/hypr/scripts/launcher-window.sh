#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/launcher-guard.sh" ]]; then
    source "$SCRIPT_DIR/launcher-guard.sh"
    guard_launcher "window"
fi

# 1. Native Hyprland Window Switcher via hyprlauncher / wofi & hyprctl
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  windows="$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.mapped == true and .title != "") | "\(.address) [ws:\(.workspace.name // .workspace.id)] \(.class): \(.title)"' || true)"
  if [[ -n "$windows" ]]; then
    selection=""
    if command -v hyprlauncher >/dev/null 2>&1; then
      selection="$(printf '%s\n' "$windows" | hyprlauncher -m || true)"
      [[ "$selection" == "Exited without selection" ]] && selection=""
    elif command -v wofi >/dev/null 2>&1; then
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

      selection="$(printf '%s\n' "$windows" | wofi --dmenu -p "Switch window..." --insensitive --hide-scroll "${WOFI_ARGS[@]}" || true)"
    fi

    if [[ -n "$selection" ]]; then
      addr="$(awk '{print $1}' <<< "$selection")"
      if [[ -n "$addr" ]]; then
        hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1 || true
        exit 0
      fi
    else
      exit 0
    fi
  fi
fi

# 2. Fallback: Rofi window switcher
if [[ -z "${ROFI_CONFIG:-}" ]]; then
  if [[ -f "$HOME/.config/rofi/config.rasi" ]]; then
    export ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
  elif [[ -f "$(dirname "$0")/../../rofi/config.rasi" ]]; then
    export ROFI_CONFIG="$(cd "$(dirname "$0")/../../rofi" && pwd)/config.rasi"
  fi
fi

if [[ -x "$HOME/.config/hypr/scripts/rofi-menu.sh" ]]; then
  exec "$HOME/.config/hypr/scripts/rofi-menu.sh" window "Windows" \
    -theme-str 'window { width: 34%; } @media ( max-width: 1500 ) { window { width: 42%; } } @media ( max-width: 1100 ) { window { width: 60%; } }' \
    -modi "window,drun,run" \
    -window-format "{w} · {c} · {t}" \
    -matching fuzzy \
    -sorting-method fzf
elif command -v rofi >/dev/null 2>&1; then
  exec rofi -show window
fi
