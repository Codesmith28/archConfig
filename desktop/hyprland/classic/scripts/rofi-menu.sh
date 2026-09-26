#!/usr/bin/env bash
set -euo pipefail

CONFIG="${ROFI_CONFIG:-$HOME/.config/rofi/config.rasi}"
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
