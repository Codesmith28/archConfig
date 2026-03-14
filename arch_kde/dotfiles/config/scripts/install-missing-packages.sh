#!/usr/bin/env bash
set -euo pipefail

PKG_FILE="${1:-$HOME/.config/scripts/hypr-packages.txt}"

if [[ ! -f "$PKG_FILE" ]]; then
  echo "Package list not found: $PKG_FILE"
  exit 1
fi

have() {
  command -v "$1" >/dev/null 2>&1
}

detect_pm() {
  if have pacman; then
    echo "pacman"
  elif have apt; then
    echo "apt"
  elif have dnf; then
    echo "dnf"
  elif have zypper; then
    echo "zypper"
  else
    echo "unsupported"
  fi
}

is_installed() {
  local pm="$1"
  local pkg="$2"

  case "$pm" in
    pacman) pacman -Q "$pkg" >/dev/null 2>&1 ;;
    apt) dpkg -s "$pkg" >/dev/null 2>&1 ;;
    dnf|zypper) rpm -q "$pkg" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

install_pkg() {
  local pm="$1"
  local pkg="$2"

  case "$pm" in
    pacman)
      if have yay; then
        yay -S --needed --noconfirm "$pkg"
      elif have paru; then
        paru -S --needed --noconfirm "$pkg"
      else
        sudo pacman -S --needed --noconfirm "$pkg"
      fi
      ;;
    apt)
      sudo apt install -y "$pkg"
      ;;
    dnf)
      sudo dnf install -y "$pkg"
      ;;
    zypper)
      sudo zypper --non-interactive install "$pkg"
      ;;
    *)
      echo "Unsupported package manager"
      return 1
      ;;
  esac
}

PM="$(detect_pm)"
if [[ "$PM" == "unsupported" ]]; then
  echo "Unsupported distro/package manager."
  exit 1
fi

if [[ "$PM" == "apt" ]]; then
  sudo apt update
fi

installed_count=0
missing_count=0
failed_count=0

while IFS= read -r line || [[ -n "$line" ]]; do
  pkg="${line%%#*}"
  pkg="$(echo "$pkg" | xargs)"

  [[ -z "$pkg" ]] && continue

  if is_installed "$PM" "$pkg"; then
    echo "[skip] already installed: $pkg"
    installed_count=$((installed_count + 1))
    continue
  fi

  echo "[install] missing package: $pkg"
  if install_pkg "$PM" "$pkg"; then
    missing_count=$((missing_count + 1))
  else
    echo "[warn] failed to install: $pkg"
    failed_count=$((failed_count + 1))
  fi
done < "$PKG_FILE"

echo
echo "Summary"
echo "- Skipped (already installed): $installed_count"
echo "- Installed now: $missing_count"
echo "- Failed: $failed_count"
