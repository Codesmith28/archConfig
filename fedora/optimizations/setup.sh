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

for dir in "$SCRIPT_DIR"/*/; do
    [ -d "$dir" ] || continue
    dir_name="$(basename "$dir")"

    # Skip library and hidden directories
    [[ "$dir_name" == "lib" || "$dir_name" =~ ^\. ]] && continue

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

    if [[ -f "$dir/install.sh" ]]; then
        log_info "Executing installer: $dir_name/install.sh"
        bash "$dir/install.sh" "$BIN_DEST" "$SERVICE_DEST"
    elif [[ -f "$dir/setup.sh" ]]; then
        log_info "Executing setup: $dir_name/setup.sh"
        bash "$dir/setup.sh" "$BIN_DEST" "$SERVICE_DEST"
    elif [[ -f "$dir/config.sh" ]]; then
        log_info "Executing configuration: $dir_name/config.sh"
        bash "$dir/config.sh" "$BIN_DEST" "$SERVICE_DEST"
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
        battery)
            echo -e "  ${GREEN}✔${NC} ${BOLD}battery${NC}        : 85% charging cap (persistent across reboot, sleep, and AC connect)"
            ;;
        config_grub)
            echo -e "  ${GREEN}✔${NC} ${BOLD}config_grub${NC}    : gfxterm graphical mode, native resolution, font in /boot, smooth handoff"
            ;;
        nvidia-power)
            echo -e "  ${GREEN}✔${NC} ${BOLD}nvidia-power${NC}   : VRAM preservation & power management configuration"
            ;;
        optimize_gnome)
            echo -e "  ${GREEN}✔${NC} ${BOLD}optimize_gnome${NC} : Fast keyrate (250ms/25ms), Super+Return terminal shortcut, keybindings, Ptyxis launcher"
            ;;
        usb-wake)
            echo -e "  ${GREEN}✔${NC} ${BOLD}usb-wake${NC}       : Working keyboard wake (internal + external), mouse/backpack wake blocked"
            ;;
        *)
            echo -e "  ${GREEN}✔${NC} ${BOLD}$mod${NC}"
            ;;
    esac
done
echo ""
