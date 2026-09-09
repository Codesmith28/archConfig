#!/usr/bin/env bash
# ==============================================================================
# omArchy Optimization - NVIDIA Power Management (Hot Backpack Fix)
# ==============================================================================
set -e

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

# 1. Hardware check: verify if an NVIDIA GPU or driver is present
has_nvidia=0
if lspci | grep -qi nvidia || lsmod | grep -q "^nvidia" || pacman -Qs "^nvidia" >/dev/null 2>&1; then
    has_nvidia=1
fi

if [[ $has_nvidia -eq 0 ]]; then
    log_warn "No NVIDIA GPU or driver detected on this system. Skipping."
    exit 0
fi

# 2. Install modprobe configuration for video memory preservation
CONF_SRC="$SCRIPT_DIR/nvidia-power-management.conf"
if [[ -f "$CONF_SRC" ]]; then
    install_modprobe_config "$CONF_SRC"
else
    log_error "Missing configuration file: $CONF_SRC"
    exit 1
fi

# 3. Enable NVIDIA systemd suspend/hibernate/resume services
SERVICES=(
    "nvidia-suspend.service"
    "nvidia-hibernate.service"
    "nvidia-resume.service"
)

log_info "Reloading systemd daemon..."
run_as_root systemctl daemon-reload

for s in "${SERVICES[@]}"; do
    if systemctl list-unit-files "$s" &>/dev/null; then
        enable_service "$s"
    else
        log_warn "Systemd unit $s not found (is nvidia-utils installed?)"
    fi
done

log_success "NVIDIA Power Management optimization configured successfully!"
