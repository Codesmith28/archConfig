#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" != "--tui" && -f "$SCRIPT_DIR/launcher-guard.sh" ]]; then
    source "$SCRIPT_DIR/launcher-guard.sh"
    guard_launcher "power"
fi
TERMINAL_BIN="${SCRIPT_DIR}/terminal.sh"

# If invoked in interactive TUI mode (inside a small floating terminal)
if [[ "${1:-}" == "--tui" ]]; then
  options=(
    "󰤄 Sleep"
    "󰑓 Reboot"
    "󰐥 Power Off"
    "󰌾 Lock"
    "󰍃 Logout"
  )
  choice=""
  if command -v fzf >/dev/null 2>&1; then
    choice="$(printf '%s\n' "${options[@]}" | fzf --reverse --no-info --prompt="Power Menu > " --header="Select Power Action (ESC to cancel)" || true)"
  else
    echo "=== Power Menu ==="
    select opt in "${options[@]}" "Cancel"; do
      choice="$opt"
      break
    done
  fi

  case "$choice" in
    *"Sleep"*)
      exec systemctl suspend
      ;;
    *"Reboot"*)
      exec systemctl reboot
      ;;
    *"Power Off"*)
      exec systemctl poweroff
      ;;
    *"Lock"*)
      if command -v hyprlock >/dev/null 2>&1; then
        exec hyprlock
      fi
      exec loginctl lock-session
      ;;
    *"Logout"*)
      if [[ -x "$SCRIPT_DIR/logout.sh" ]]; then
        exec "$SCRIPT_DIR/logout.sh"
      fi
      exec hyprctl dispatch exit
      ;;
    *)
      exit 0
      ;;
  esac
fi

POWER_OPTIONS=$'󰤄 Sleep\n󰑓 Reboot\n󰐥 Power Off\n󰌾 Lock\n󰍃 Logout'
choice=""

# 1. Native hyprlauncher dmenu mode
if command -v hyprlauncher >/dev/null 2>&1; then
  raw_sel="$(printf '%s\n' "$POWER_OPTIONS" | hyprlauncher -m || true)"
  if [[ -n "$raw_sel" && "$raw_sel" != "Exited without selection" ]]; then
    choice="$raw_sel"
  else
    exit 0
  fi
fi

# 2. Modern Wayland dmenu: wofi --dmenu (fit-content sizing: 5 lines, 280px width)
if [[ -z "$choice" ]] && command -v wofi >/dev/null 2>&1; then
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

  WOFI_ARGS=(--lines 5 --width 300 --prompt "Power Menu" --insensitive --hide-scroll)
  [[ -n "$wofi_conf" ]] && WOFI_ARGS+=(--conf "$wofi_conf")
  [[ -n "$wofi_style" ]] && WOFI_ARGS+=(--style "$wofi_style")

  raw_sel="$(printf '%s\n' "$POWER_OPTIONS" | wofi --dmenu "${WOFI_ARGS[@]}" 2>/dev/null || true)"
  if [[ -n "$raw_sel" ]]; then
    choice="$raw_sel"
  else
    # User cancelled (e.g. pressed ESC or clicked away): exit cleanly without opening terminal
    exit 0
  fi
fi

# 3. Fallback: Rofi power menu
if [[ -z "$choice" ]] && command -v rofi >/dev/null 2>&1; then
  if [[ -x "${SCRIPT_DIR}/rofi-menu.sh" ]]; then
    choice="$(printf '%s\n' "$POWER_OPTIONS" | "${SCRIPT_DIR}/rofi-menu.sh" dmenu "Power" \
      -theme-str 'window { width: 20%; }' 2>/dev/null || true)"
  fi
  if [[ -z "$choice" ]]; then
    exit 0
  fi
fi

# 4. Fallback: wlogout
if [[ -z "$choice" ]] && command -v wlogout >/dev/null 2>&1; then
  exec wlogout
fi

if [[ -z "$choice" ]]; then
  exit 0
fi

case "$choice" in
  *"Lock"*)
    if command -v hyprlock >/dev/null 2>&1; then
      exec hyprlock
    fi
    exec loginctl lock-session
    ;;
  *"Sleep"*)
    exec systemctl suspend
    ;;
  *"Logout"*)
    if [[ -x "$SCRIPT_DIR/logout.sh" ]]; then
      exec "$SCRIPT_DIR/logout.sh"
    elif [[ -x "$HOME/.config/hypr/scripts/logout.sh" ]]; then
      exec "$HOME/.config/hypr/scripts/logout.sh"
    fi
    exec hyprctl dispatch exit
    ;;
  *"Reboot"*)
    exec systemctl reboot
    ;;
  *"Power Off"*|*"Shutdown"*)
    exec systemctl poweroff
    ;;
  *)
    exit 0
    ;;
esac
