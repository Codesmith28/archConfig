#!/usr/bin/env bash
# ==============================================================================
# Default Terminal Resolver for Hyprland
# ==============================================================================
# Resolves the system / GNOME default terminal dynamically (Ptyxis,
# desktop/gnome/default-terminal, xdg-terminal-exec, gnome-terminal),
# falling back gracefully to Kitty or Ghostty.
# ==============================================================================
set -euo pipefail

# 1. Check GNOME desktop preference
if command -v gsettings >/dev/null 2>&1; then
    GNOME_TERM="$(gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null | tr -d "'\"" || true)"
    if [[ -n "$GNOME_TERM" ]] && command -v "$GNOME_TERM" >/dev/null 2>&1; then
        exec "$GNOME_TERM" "$@"
    fi
fi

# 2. Check xdg-terminal-exec (systemd / freedesktop standard)
if command -v xdg-terminal-exec >/dev/null 2>&1 && [[ $# -eq 0 ]]; then
    exec xdg-terminal-exec
fi

# 3. GNOME default terminal: Ptyxis (default in Fedora GNOME)
if command -v ptyxis >/dev/null 2>&1; then
    args=()
    skip_next=false
    for arg in "$@"; do
        if [[ "$skip_next" == true ]]; then
            skip_next=false
            continue
        fi
        if [[ "$arg" == "--class" ]]; then
            skip_next=true
            continue
        elif [[ "$arg" == --class=* ]]; then
            continue
        elif [[ "$arg" == "-e" ]]; then
            args+=("--")
        else
            args+=("$arg")
        fi
    done
    exec ptyxis "${args[@]}"
fi

# 4. Standard GNOME terminal
if command -v gnome-terminal >/dev/null 2>&1; then
    exec gnome-terminal "$@"
fi

# 5. Additional / Standalone terminals (Ghostty, Foot, Konsole, Alacritty, WezTerm, XTerm)
for term in ghostty foot konsole alacritty wezterm xterm; do
    if command -v "$term" >/dev/null 2>&1; then
        if [[ "$term" == "ghostty" ]]; then
            gargs=()
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --class)
                        if [[ $# -gt 1 ]]; then
                            gargs+=("--class=$2")
                            shift 2
                        else
                            shift
                        fi
                        ;;
                    *)
                        gargs+=("$1")
                        shift
                        ;;
                esac
            done
            exec ghostty "${gargs[@]}"
        fi
        exec "$term" "$@"
    fi
done

echo "Error: No supported terminal emulator found." >&2
exit 1
