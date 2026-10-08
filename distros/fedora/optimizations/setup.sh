#!/usr/bin/env bash
# ==============================================================================
# System Optimizations - Setup Script (Fedora / Linux)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library functions
source "$SCRIPT_DIR/lib/common.sh"

BIN_DEST="${BIN_DEST:-/usr/local/bin}"
SERVICE_DEST="${SERVICE_DEST:-/etc/systemd/system}"

DISTRO_NAME="$(grep ^NAME= /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "Linux")"
log_info "Starting ${DISTRO_NAME} optimizations setup..."

# Parse optional module filter arguments: e.g. ./setup.sh battery gnome grub
REQUESTED_MODULES=("$@")

# Helper to check if a module name matches user filter
should_run_module() {
    local mod="$1"
    if [[ ${#REQUESTED_MODULES[@]} -eq 0 ]]; then
        return 0
    fi
    for req in "${REQUESTED_MODULES[@]}"; do
        if [[ "$mod" == "$req" || "$mod" == *"$req"* ]]; then
            return 0
        fi
    done
    return 1
}

# Ensure destination directories exist
if [[ ! -d "$BIN_DEST" || ! -d "$SERVICE_DEST" ]]; then
    run_as_root mkdir -p "$BIN_DEST" "$SERVICE_DEST"
fi

executed_modules=()

# Explicit module execution order:
# 1. config_grub runs to configure the bootloader and graphical terminal.
# 2. appstream refreshes RPM Fusion appstream metadata.
ORDERED_MODULES=("config_grub" "appstream")

detect_desktop() {
    local de="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
    de=$(echo "$de" | tr '[:upper:]' '[:lower:]')
    if echo "$de" | grep -qE "kde|plasma" || [ -n "${KDE_FULL_SESSION:-}" ] || [ -n "${KDE_SESSION_VERSION:-}" ] || pgrep -x "plasmashell" >/dev/null 2>&1 || pgrep -x "kwin_wayland" >/dev/null 2>&1; then
        echo "kde"
    elif echo "$de" | grep -q "gnome" || pgrep -x "gnome-shell" >/dev/null 2>&1; then
        echo "gnome"
    elif [ -f /usr/share/wayland-sessions/plasmawayland.desktop ] || [ -f /usr/share/wayland-sessions/plasma.desktop ]; then
        echo "kde"
    elif [ -f /usr/share/wayland-sessions/gnome.desktop ]; then
        echo "gnome"
    else
        echo "none"
    fi
}

# Select desktop environment optimization module
if [[ ${#REQUESTED_MODULES[@]} -eq 0 ]]; then
    ACTIVE_DE="$(detect_desktop)"
    if [ "$ACTIVE_DE" = "kde" ] && [ -d "$SCRIPT_DIR/optimize_kde" ]; then
        ORDERED_MODULES+=("optimize_kde")
    elif [ "$ACTIVE_DE" = "gnome" ] && [ -d "$SCRIPT_DIR/optimize_gnome" ]; then
        ORDERED_MODULES+=("optimize_gnome")
    fi
else
    for m in "optimize_gnome" "optimize_kde"; do
        if should_run_module "$m" && [ -d "$SCRIPT_DIR/$m" ]; then
            ORDERED_MODULES+=("$m")
        fi
    done
fi

# Build prioritized list of modules
MODULES_TO_RUN=()
for mod in "${ORDERED_MODULES[@]}"; do
    if [[ -d "$SCRIPT_DIR/$mod" ]]; then
        MODULES_TO_RUN+=("$mod")
    fi
done

# Dynamically discover any other custom modules not explicitly listed
for dir in "$SCRIPT_DIR"/*/; do
    [ -d "$dir" ] || continue
    dir_name="$(basename "$dir")"
    [[ "$dir_name" == "lib" || "$dir_name" =~ ^\. || "$dir_name" == "optimize_gnome" || "$dir_name" == "optimize_kde" ]] && continue
    already_listed=0
    for m in "${MODULES_TO_RUN[@]}"; do
        if [[ "$m" == "$dir_name" ]]; then
            already_listed=1
            break
        fi
    done
    if [[ $already_listed -eq 0 ]]; then
        MODULES_TO_RUN+=("$dir_name")
    fi
done

for dir_name in "${MODULES_TO_RUN[@]}"; do
    dir="$SCRIPT_DIR/$dir_name"
    [ -d "$dir" ] || continue

    if ! should_run_module "$dir_name"; then
        continue
    fi

    echo ""
    log_info "=================================================================="
    log_info "Configuring module: ${BOLD}${dir_name}${NC}"
    log_info "=================================================================="

    if ! validate_optimization_dir "$dir"; then
        log_warn "Validation failed for module: $dir_name (skipping)"
        continue
    fi

    if [[ -f "$dir/setup.sh" ]]; then
        log_info "Executing setup: $dir_name/setup.sh"
        bash "$dir/setup.sh" "$BIN_DEST" "$SERVICE_DEST"
    elif [[ -f "$dir/install.sh" ]]; then
        log_info "Executing installer: $dir_name/install.sh"
        bash "$dir/install.sh" "$BIN_DEST" "$SERVICE_DEST"
    else
        install_optimization "$dir" "$BIN_DEST" "$SERVICE_DEST"
    fi

    executed_modules+=("$dir_name")
done

echo ""
log_info "=================================================================="
log_success "All optimization modules executed successfully!"
log_info "=================================================================="
echo -e "${BOLD}Summary of configured optimizations:${NC}"
for mod in "${executed_modules[@]}"; do
    case "$mod" in
        config_grub)
            echo -e "  ${GREEN}✔${NC} ${BOLD}config_grub${NC}    : gfxterm graphical mode, native resolution, font in /boot, smooth handoff"
            ;;
        optimize_gnome)
            echo -e "  ${GREEN}✔${NC} ${BOLD}optimize_gnome${NC} : Fast keyrate (250ms/25ms), Super+Return terminal shortcut, keybindings, Ptyxis launcher"
            ;;
        optimize_kde)
            echo -e "  ${GREEN}✔${NC} ${BOLD}optimize_kde${NC}   : KDE Plasma shortcuts, Meta+Return terminal, keyrate (250ms/40Hz), titlebars"
            ;;
        appstream)
            echo -e "  ${GREEN}✔${NC} ${BOLD}appstream${NC}      : RPM Fusion AppStream metadata & PackageKit refresh (RPMs in App Store)"
            ;;
        *)
            echo -e "  ${GREEN}✔${NC} ${BOLD}$mod${NC}"
            ;;
    esac
done
echo ""
