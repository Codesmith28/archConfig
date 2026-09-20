#!/usr/bin/env bash
# ==============================================================================
# NVIDIA Power Management (VRAM Preservation & Suspend/Resume)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source common library functions
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
else
    echo "[ERR] Common library not found: $LIB_DIR/common.sh" >&2
    exit 1
fi

log_info "Configuring NVIDIA Power Management for suspend/resume..."

# 1. Hardware check: verify if an NVIDIA GPU is present
gpu_pci=$(lspci | grep -iE "(VGA|3D).*NVIDIA" | awk '{print $1}' | head -n 1 || true)
if [[ -z "$gpu_pci" ]]; then
    log_warn "No NVIDIA GPU detected on this system. Skipping."
    exit 0
fi

full_pci=$(lspci -s "$gpu_pci" -D | awk '{print $1}')
active_driver=$(basename "$(readlink "/sys/bus/pci/devices/${full_pci}/driver" 2>/dev/null || echo "none")")
gpu_name=$(lspci -s "$gpu_pci" | sed -E 's/.*controller: //')

log_info "Detected GPU: ${BOLD}${gpu_name}${NC} (PCI: $full_pci, Active Driver: ${BOLD}${active_driver}${NC})"

# 2. Install modprobe configuration for video memory preservation
CONF_SRC="$SCRIPT_DIR/nvidia-power-management.conf"
if [[ -f "$CONF_SRC" ]]; then
    install_modprobe_config "$CONF_SRC"
else
    log_error "Missing configuration file: $CONF_SRC"
    exit 1
fi

# 3. Handle systemd services based on active driver
SERVICES=(
    "nvidia-suspend.service"
    "nvidia-hibernate.service"
    "nvidia-resume.service"
)

if [[ "$active_driver" == "nvidia" ]]; then
    log_info "Reloading systemd daemon..."
    run_as_root systemctl daemon-reload

    for s in "${SERVICES[@]}"; do
        if systemctl list-unit-files "$s" &>/dev/null; then
            enable_service "$s"
        else
            log_warn "Systemd unit $s not found (is nvidia-utils installed?)"
        fi
    done
    log_success "Proprietary NVIDIA Power Management services configured!"
elif [[ "$active_driver" == "nouveau" ]]; then
    log_info "Open-source 'nouveau' driver is active. Dynamic runtime PM and D3cold power management are handled directly by the kernel."
    log_info "Modprobe configuration staged for video memory preservation when proprietary drivers are installed."
    log_success "NVIDIA power management configuration completed!"
else
    log_info "No active kernel driver for NVIDIA GPU. Staged modprobe configuration ready."
fi
