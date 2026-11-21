#!/usr/bin/env bash
set -euo pipefail

CONFIG="${ROFI_CONFIG:-}"
if [[ -z "$CONFIG" ]]; then
  if [[ -f "$HOME/.config/rofi/config.rasi" ]]; then
    CONFIG="$HOME/.config/rofi/config.rasi"
  elif [[ -f "$(dirname "$0")/../../rofi/config.rasi" ]]; then
    CONFIG="$(cd "$(dirname "$0")/../../rofi" && pwd)/config.rasi"
  else
    CONFIG="$HOME/.config/rofi/config.rasi"
  fi
fi

MODE="${1:-drun}"
PROMPT="${2:-Menu}"

if [[ $# -gt 0 ]]; then
  shift
fi
if [[ $# -gt 0 ]]; then
  shift
fi

EXTRA_ARGS=("$@")

case "$MODE" in
  dmenu)
    exec rofi -config "$CONFIG" -dmenu -i -p "$PROMPT" "${EXTRA_ARGS[@]}"
    ;;
  *)
    exec rofi -config "$CONFIG" -show "$MODE" -p "$PROMPT" "${EXTRA_ARGS[@]}"
    ;;
esac
