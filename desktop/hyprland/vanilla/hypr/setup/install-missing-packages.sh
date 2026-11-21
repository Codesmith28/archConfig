#!/usr/bin/env bash
# ==============================================================================
# Install Missing Hyprland Native Packages
# ==============================================================================
# Lean package installer that checks for existing GNOME / system equivalents
# before attempting installation.
# Supports --dry-run to simulate without root / sudo privileges.
# ==============================================================================
set -euo pipefail

DRY_RUN=false
pkg_file=""

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n)
      DRY_RUN=true
      ;;
    *)
      if [[ -z "$pkg_file" && -f "$arg" ]]; then
        pkg_file="$arg"
      fi
      ;;
  esac
done

if [[ -z "$pkg_file" ]]; then
  pkg_file="${pkg_file:-$HOME/.config/hypr/setup/packages.txt}"
  if [[ ! -f "$pkg_file" ]]; then
    pkg_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/packages.txt"
  fi
fi
[[ -f "$pkg_file" ]] || { echo "Missing package list: $pkg_file"; exit 1; }

# Determine package manager
if command -v dnf >/dev/null 2>&1; then
  check_cmd=(rpm -q)
  install_cmd=(sudo dnf install -y)
elif command -v yay >/dev/null 2>&1; then
  check_cmd=(pacman -Q)
  install_cmd=(yay -S --needed --noconfirm)
elif command -v paru >/dev/null 2>&1; then
  check_cmd=(pacman -Q)
  install_cmd=(paru -S --needed --noconfirm)
elif command -v pacman >/dev/null 2>&1; then
  check_cmd=(pacman -Q)
  install_cmd=(sudo pacman -S --needed --noconfirm)
else
  echo "Unsupported package manager. Please install packages manually."
  exit 1
fi

# Check if package or its functional equivalent is satisfied
is_satisfied() {
  local p="$1"
  if "${check_cmd[@]}" "$p" >/dev/null 2>&1; then
    return 0
  fi
  # Check functional binary equivalents
  case "$p" in
    hyprland) command -v Hyprland >/dev/null 2>&1 ;;
    waybar) command -v waybar >/dev/null 2>&1 ;;
    hyprlauncher) command -v hyprlauncher >/dev/null 2>&1 ;;
    wofi) command -v wofi >/dev/null 2>&1 ;;
    rofi) command -v rofi >/dev/null 2>&1 ;;
    rofi-emoji) [ -f /usr/lib64/rofi/emoji.so ] || [ -f /usr/lib/rofi/emoji.so ] || command -v rofi-emoji >/dev/null 2>&1 ;;
    hyprpaper) command -v hyprpaper >/dev/null 2>&1 ;;
    hyprlock) command -v hyprlock >/dev/null 2>&1 ;;
    hypridle) command -v hypridle >/dev/null 2>&1 ;;
    hyprshot) command -v hyprshot >/dev/null 2>&1 ;;
    hyprpicker) command -v hyprpicker >/dev/null 2>&1 ;;
    hyprpolkitagent) command -v hyprpolkitagent >/dev/null 2>&1 || [ -x /usr/libexec/hyprpolkitagent ] || [ -x /usr/lib/hyprpolkitagent ] ;;
    swaync) command -v swaync >/dev/null 2>&1 ;;
    wlogout) command -v wlogout >/dev/null 2>&1 ;;
    clipse) command -v clipse >/dev/null 2>&1 ;;
    grim) command -v grim >/dev/null 2>&1 ;;
    slurp) command -v slurp >/dev/null 2>&1 ;;
    swappy) command -v swappy >/dev/null 2>&1 ;;
    brightnessctl) command -v brightnessctl >/dev/null 2>&1 ;;
    playerctl) command -v playerctl >/dev/null 2>&1 ;;
    blueman) command -v blueman-manager >/dev/null 2>&1 ;;
    bluetuith) command -v bluetuith >/dev/null 2>&1 || command -v bluetui >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

skipped=0
installed=0
failed=0

while IFS= read -r line || [[ -n "$line" ]]; do
  pkg="${line%%#*}"
  pkg="$(echo "$pkg" | xargs)"
  [[ -z "$pkg" ]] && continue

  if is_satisfied "$pkg"; then
    echo "[skip] $pkg (satisfied)"
    ((++skipped))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] would install $pkg"
    ((++installed))
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
