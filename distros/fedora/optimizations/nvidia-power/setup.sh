#!/usr/bin/env bash
# ==============================================================================
# NVIDIA Power Management Setup (VRAM Preservation & Suspend/Resume)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source common library functions
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
else
    log_info()    { echo "[INFO] $*"; }
    log_success() { echo "[OK]   $*"; }
    log_warn()    { echo "[WARN] $*" >&2; }
    log_error()   { echo "[ERR]  $*" >&2; }
    run_as_root() {
        if [[ "$(id -u)" -eq 0 ]]; then
            "$@"
        elif command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            log_error "Root privileges required. Please run with sudo or as root."
            exit 1
        fi
    }
fi

verify_nvidia() {
    echo -e "\n${BOLD}=== NVIDIA Power Management Status Check ===${NC}\n"

    # 1. Check GPU hardware and active driver
    gpu_pci=$(lspci 2>/dev/null | grep -iE "(VGA|3D).*NVIDIA" | awk '{print $1}' | head -n 1 || true)
    if [[ -z "$gpu_pci" ]]; then
        log_warn "No NVIDIA GPU detected."
        return 0
    fi

    full_pci=$(lspci -s "$gpu_pci" -D 2>/dev/null | awk '{print $1}')
    active_driver=$(basename "$(readlink "/sys/bus/pci/devices/${full_pci}/driver" 2>/dev/null || echo "none")")
    gpu_name=$(lspci -s "$gpu_pci" 2>/dev/null | sed -E 's/.*controller: //')

    log_info "Detected GPU: ${BOLD}${gpu_name}${NC} ($full_pci)"
    log_info "Active kernel driver: ${BOLD}${active_driver}${NC}"

    # 2. Check modprobe config
    CONF_FILE="/etc/modprobe.d/nvidia-power-management.conf"
    if [[ -f "$CONF_FILE" ]]; then
        log_success "Modprobe config file exists: $CONF_FILE"
    else
        log_warn "Modprobe config NOT found at $CONF_FILE"
    fi

    # 3. Check driver-specific parameters and services
    if [[ "$active_driver" == "nvidia" ]]; then
        if [[ -f /proc/driver/nvidia/params ]]; then
            val=$(grep "PreserveVideoMemoryAllocations:" /proc/driver/nvidia/params | awk '{print $2}')
            if [[ "$val" == "1" ]]; then
                log_success "Kernel parameter PreserveVideoMemoryAllocations is active: $val"
            else
                log_warn "Kernel parameter PreserveVideoMemoryAllocations is NOT 1 (current: $val)"
            fi
        else
            log_warn "/proc/driver/nvidia/params not accessible (GPU in D3cold or driver not loaded)"
        fi

        echo ""
        log_info "Checking NVIDIA systemd power management services:"
        SERVICES=("nvidia-suspend.service" "nvidia-hibernate.service" "nvidia-resume.service")
        all_enabled=1
        for s in "${SERVICES[@]}"; do
            state=$(systemctl is-enabled "$s" 2>/dev/null) || state="${state:-not-found}"
            if [[ "$state" == "enabled" ]]; then
                log_success "Systemd unit $s: ${BOLD}$state${NC}"
            else
                log_error "Systemd unit $s: ${BOLD}$state${NC}"
                all_enabled=0
            fi
        done
        echo ""
        if [[ $all_enabled -eq 1 ]]; then
            log_success "All proprietary NVIDIA suspend/resume services are active!"
        fi
    elif [[ "$active_driver" == "nouveau" ]]; then
        echo ""
        log_success "Nouveau open-source driver is active. Kernel runtime PM and D3cold low-power states are handled directly by the kernel."
        log_info "Proprietary systemd hook units are not needed under Nouveau."
    fi
    echo ""
}

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    verify_nvidia
    exit 0
fi

log_info "Configuring NVIDIA Power Management for suspend/resume..."

# 1. Hardware check: verify if an NVIDIA GPU is present
gpu_pci=$(lspci 2>/dev/null | grep -iE "(VGA|3D).*NVIDIA" | awk '{print $1}' | head -n 1 || true)
if [[ -z "$gpu_pci" ]]; then
    log_warn "No NVIDIA GPU detected on this system. Skipping."
    exit 0
fi

full_pci=$(lspci -s "$gpu_pci" -D 2>/dev/null | awk '{print $1}')
active_driver=$(basename "$(readlink "/sys/bus/pci/devices/${full_pci}/driver" 2>/dev/null || echo "none")")
gpu_name=$(lspci -s "$gpu_pci" 2>/dev/null | sed -E 's/.*controller: //')

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

# 4. Verify configuration
verify_nvidia
