#!/usr/bin/env bash
set -euo pipefail

pkg_file="${1:-$HOME/.config/hypr/setup/packages.txt}"
[[ -f "$pkg_file" ]] || { echo "Missing package list: $pkg_file"; exit 1; }

if command -v yay >/dev/null 2>&1; then
  check_cmd=(pacman -Q)
  install_cmd=(yay -S --needed --noconfirm)
elif command -v paru >/dev/null 2>&1; then
  check_cmd=(pacman -Q)
  install_cmd=(paru -S --needed --noconfirm)
elif command -v pacman >/dev/null 2>&1; then
  check_cmd=(pacman -Q)
  install_cmd=(sudo pacman -S --needed --noconfirm)
else
  echo "This minimal script supports Arch-based systems only (pacman/yay/paru)."
  exit 1
fi

skipped=0
installed=0
failed=0

while IFS= read -r line || [[ -n "$line" ]]; do
  pkg="${line%%#*}"
  pkg="$(echo "$pkg" | xargs)"
  [[ -z "$pkg" ]] && continue

  if "${check_cmd[@]}" "$pkg" >/dev/null 2>&1; then
    echo "[skip] $pkg"
    ((++skipped))
    continue
  fi

  echo "[install] $pkg"
  if "${install_cmd[@]}" "$pkg"; then
    ((++installed))
  else
    echo "[fail] $pkg"
    ((++failed))
  fi
done < "$pkg_file"

echo
echo "Summary: skipped=$skipped installed=$installed failed=$failed"
