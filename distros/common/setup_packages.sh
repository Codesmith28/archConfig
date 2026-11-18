#!/usr/bin/env bash
# ==============================================================================
# archConfig Lean Agnostic Linux Package Setup
#
# Provides lean, non-bloated, essential developer tooling across:
#   - Arch Linux / OmArchy (pacman)
#   - Fedora (dnf)
#   - Ubuntu / Debian (apt)
#
# Installs only core requirements:
#   - Base CLI: git, curl, tar, unzip
#   - Editor: neovim
#   - Navigation / Search: ripgrep, fd/fd-find, bat, fzf, zoxide
#   - Build tools: base-devel / gcc-c++ / build-essential
#
# Ensures compatibility aliases:
#   - Symlinks fdfind -> ~/.local/bin/fd (for Ubuntu/Debian)
#   - Symlinks batcat -> ~/.local/bin/bat (for Ubuntu/Debian)
# ==============================================================================
set -euo pipefail

DRY_RUN=false
NON_INTERACTIVE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --non-interactive|-y) NON_INTERACTIVE=true ;;
    esac
done

BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
mkdir -p "$BIN_DIR"

detect_manager() {
    if command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    else
        echo "unknown"
    fi
}

PKG_MANAGER="$(detect_manager)"

echo "==> Linux Package Manager detected: $PKG_MANAGER"

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "  (dry-run) Would run: $*"
    else
        if [ "$EUID" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            "$@"
        fi
    fi
}

case "$PKG_MANAGER" in
    pacman)
        # Lean Arch essentials (no bloat)
        ARCH_PKGS=(
            git curl tar unzip
            neovim
            ripgrep fd bat fzf zoxide
            base-devel
        )
        PACMAN_FLAGS=("-S" "--needed")
        if [ "$NON_INTERACTIVE" = true ]; then
            PACMAN_FLAGS+=("--noconfirm")
        fi
        echo "==> Installing lean Arch package set..."
        run_cmd pacman "${PACMAN_FLAGS[@]}" "${ARCH_PKGS[@]}"
        ;;

    dnf)
        # Lean Fedora essentials (no bloat)
        FEDORA_PKGS=(
            git curl tar unzip
            neovim
            ripgrep fd-find bat fzf zoxide
            gcc gcc-c++ make
        )
        DNF_FLAGS=("install")
        if [ "$NON_INTERACTIVE" = true ]; then
            DNF_FLAGS+=("-y")
        fi
        echo "==> Installing lean Fedora package set..."
        run_cmd dnf "${DNF_FLAGS[@]}" "${FEDORA_PKGS[@]}"
        ;;

    apt)
        # Lean Ubuntu / Debian essentials (no bloat)
        UBUNTU_PKGS=(
            git curl tar unzip
            neovim
            ripgrep fd-find bat fzf zoxide
            build-essential
        )
        APT_FLAGS=("install")
        if [ "$NON_INTERACTIVE" = true ]; then
            APT_FLAGS+=("-y")
        fi
        echo "==> Updating apt cache and installing lean Ubuntu package set..."
        run_cmd apt-get update -y
        run_cmd apt-get "${APT_FLAGS[@]}" "${UBUNTU_PKGS[@]}"
        ;;

    *)
        echo "  ⚠️ Warning: Unsupported Linux package manager. Skipping system package installation."
        ;;
esac

# ------------------------------------------------------------------------------
# Compatibility Symlinks for fd and bat (Debian/Ubuntu naming parity)
# ------------------------------------------------------------------------------
setup_compat_symlinks() {
    # 1. fd symlink (Ubuntu installs as fdfind)
    if ! command -v fd >/dev/null 2>&1; then
        local fdfind_path
        fdfind_path="$(command -v fdfind || true)"
        if [ -n "$fdfind_path" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  (dry-run) Would symlink $BIN_DIR/fd -> $fdfind_path"
            else
                ln -sf "$fdfind_path" "$BIN_DIR/fd"
                echo "  ✓ Linked compatibility binary: $BIN_DIR/fd -> $fdfind_path"
            fi
        fi
    fi

    # 2. bat symlink (Ubuntu installs as batcat)
    if ! command -v bat >/dev/null 2>&1; then
        local batcat_path
        batcat_path="$(command -v batcat || true)"
        if [ -n "$batcat_path" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  (dry-run) Would symlink $BIN_DIR/bat -> $batcat_path"
            else
                ln -sf "$batcat_path" "$BIN_DIR/bat"
                echo "  ✓ Linked compatibility binary: $BIN_DIR/bat -> $batcat_path"
            fi
        fi
    fi
}

setup_compat_symlinks
echo "==> Lean Linux package setup complete."
