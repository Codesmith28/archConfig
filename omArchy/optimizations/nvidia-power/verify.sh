#!/usr/bin/env bash
# ==============================================================================
# omArchy Optimization - NVIDIA Power Management Verification
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source common library functions
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
fi

echo -e "\n${BOLD}=== NVIDIA Power Management Status Check ===${NC}\n"

# 1. Check modprobe config
CONF_FILE="/etc/modprobe.d/nvidia-power-management.conf"
if [[ -f "$CONF_FILE" ]]; then
    log_success "Modprobe config file exists: $CONF_FILE"
    echo "--- Contents of $CONF_FILE ---"
    grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -v '^[[:space:]]*$' | sed 's/^/    /'
    echo "----------------------------------------"
else
    log_warn "Modprobe config NOT found at $CONF_FILE"
fi

# 2. Check active kernel driver parameter
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

# 3. Check systemd suspend / hibernate / resume services
SERVICES=(
    "nvidia-suspend.service"
    "nvidia-hibernate.service"
    "nvidia-resume.service"
)

echo ""
log_info "Checking NVIDIA systemd power management services:"
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
if [[ $all_enabled -eq 1 && -f "$CONF_FILE" ]]; then
    log_success "All NVIDIA suspend/resume power optimizations are properly configured!"
else
    log_warn "Some components are not yet active. Run 'install.sh' to configure."
fi
echo ""
