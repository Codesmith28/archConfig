#!/usr/bin/env bash
# ==============================================================================
# NVIDIA Power Management Verification
# ==============================================================================
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
fi

echo -e "\n${BOLD}=== NVIDIA Power Management Status Check ===${NC}\n"

# 1. Check GPU hardware and active driver
gpu_pci=$(lspci | grep -iE "(VGA|3D).*NVIDIA" | awk '{print $1}' | head -n 1 || true)
if [[ -z "$gpu_pci" ]]; then
    log_warn "No NVIDIA GPU detected."
    exit 0
fi

full_pci=$(lspci -s "$gpu_pci" -D | awk '{print $1}')
active_driver=$(basename "$(readlink "/sys/bus/pci/devices/${full_pci}/driver" 2>/dev/null || echo "none")")
gpu_name=$(lspci -s "$gpu_pci" | sed -E 's/.*controller: //')

log_info "Detected GPU: ${BOLD}${gpu_name}${NC} ($full_pci)"
log_info "Active kernel driver: ${BOLD}${active_driver}${NC}"

# 2. Check modprobe config
CONF_FILE="/etc/modprobe.d/nvidia-power-management.conf"
if [[ -f "$CONF_FILE" ]]; then
    log_success "Modprobe config file exists: $CONF_FILE"
    echo "--- Contents of $CONF_FILE ---"
    grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -v '^[[:space:]]*$' | sed 's/^/    /'
    echo "----------------------------------------"
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
