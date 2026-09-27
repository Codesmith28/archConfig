#!/usr/bin/env bash
# ==============================================================================
# NVIDIA Power Management Setup (VRAM Preservation & Suspend/Resume)
# Distro-agnostic implementation for Fedora, Arch Linux, Ubuntu, and derivatives
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
            log_error "Root privileges required."
            exit 1
        fi
    }
fi

has_nvidia() {
    lspci 2>/dev/null | grep -qiE "(VGA|3D|Display).*NVIDIA" || \
    [[ -d /proc/driver/nvidia ]] || \
    [[ -d /sys/module/nvidia ]] || \
    [[ -d /sys/module/nouveau ]]
}

rebuild_initramfs() {
    if command -v dracut >/dev/null 2>&1; then
        log_info "Updating initramfs via dracut..."
        run_as_root dracut -f
    elif command -v mkinitcpio >/dev/null 2>&1; then
        log_info "Updating initramfs via mkinitcpio..."
        run_as_root mkinitcpio -P
    elif command -v update-initramfs >/dev/null 2>&1; then
        log_info "Updating initramfs via update-initramfs..."
        run_as_root update-initramfs -u
    fi
}

verify_nvidia() {
    echo -e "\n${BOLD}=== NVIDIA Power Management Status Check ===${NC}\n"

    if ! has_nvidia; then
        log_warn "No NVIDIA GPU detected on this system."
        return 0
    fi

    # 1. Modprobe configuration
    local conf="/etc/modprobe.d/nvidia-power-management.conf"
    if [[ -f "$conf" ]]; then
        log_success "Modprobe config exists: $conf"
        if grep -q "NVreg_TemporaryFilePath=/var/lib/systemd/sleep" "$conf"; then
            log_success "Temporary sleep path: /var/lib/systemd/sleep (universal standard)"
        fi
    else
        log_warn "Modprobe config NOT found at $conf"
    fi

    # 2. Kernel parameter
    if [[ -f /proc/driver/nvidia/params ]]; then
        local val
        val=$(grep "PreserveVideoMemoryAllocations:" /proc/driver/nvidia/params | awk '{print $2}')
        if [[ "$val" == "1" ]]; then
            log_success "Kernel parameter PreserveVideoMemoryAllocations is active: 1"
        else
            log_warn "Kernel parameter PreserveVideoMemoryAllocations is NOT 1 (current: $val)"
        fi
    fi

    # 3. Systemd power management services
    echo ""
    log_info "Checking NVIDIA systemd power management services:"
    local services=("nvidia-suspend.service" "nvidia-hibernate.service" "nvidia-resume.service")
    for s in "${services[@]}"; do
        local state
        state=$(systemctl is-enabled "$s" 2>/dev/null) || state="${state:-not-found}"
        if [[ "$state" == "enabled" ]]; then
            log_success "Unit $s: $state"
        else
            log_warn "Unit $s: $state"
        fi
    done
    echo ""
}

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    verify_nvidia
    exit 0
fi

log_info "Configuring NVIDIA Power Management for suspend/resume..."

# 1. Check hardware
if ! has_nvidia; then
    log_warn "No NVIDIA GPU or driver detected on this system. Skipping."
    exit 0
fi

# 2. Ensure /var/lib/systemd/sleep exists with secure permissions
log_info "Ensuring /var/lib/systemd/sleep exists..."
run_as_root mkdir -p /var/lib/systemd/sleep
run_as_root chmod 700 /var/lib/systemd/sleep
if command -v restorecon >/dev/null 2>&1; then
    run_as_root restorecon -v /var/lib/systemd/sleep || true
fi

# 3. Install modprobe configuration
CONF_SRC="$SCRIPT_DIR/nvidia-power-management.conf"
if [[ -f "$CONF_SRC" ]]; then
    install_modprobe_config "$CONF_SRC"
else
    log_error "Missing configuration file: $CONF_SRC"
    exit 1
fi

# 4. Enable systemd sleep services
SERVICES=("nvidia-suspend.service" "nvidia-hibernate.service" "nvidia-resume.service")
if [[ -d /sys/module/nvidia ]] || systemctl list-unit-files nvidia-suspend.service &>/dev/null; then
    run_as_root systemctl daemon-reload
    for s in "${SERVICES[@]}"; do
        if systemctl list-unit-files "$s" &>/dev/null; then
            enable_service "$s"
        else
            log_warn "Systemd unit $s not found (ensure NVIDIA driver/utils package is installed)"
        fi
    done
fi

# 5. Rebuild initramfs across all distros
rebuild_initramfs

# 6. Verify
verify_nvidia
