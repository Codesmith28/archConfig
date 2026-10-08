#!/usr/bin/env bash
# ==============================================================================
# Hardware Profile Setup: ASUS ROG + NVIDIA RTX Laptop
# Distro-agnostic power management, D3cold, Cardwire eBPF isolation & AC/Battery switching
# Validated for Fedora, Arch Linux, Ubuntu, and OmArchy
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color formatting
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'
NC=$'\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error()   { echo -e "${RED}[ERR]${NC}  $*" >&2; }

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

# ------------------------------------------------------------------------------
# Hardware Validation: ASUS ROG / TUF + NVIDIA dGPU Guard
# ------------------------------------------------------------------------------
is_rog_machine() {
    local prod_fam prod_name sys_ven board_name
    prod_fam="$(cat /sys/class/dmi/id/product_family 2>/dev/null || true)"
    prod_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
    sys_ven="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
    board_name="$(cat /sys/class/dmi/id/board_name 2>/dev/null || true)"
    echo "$prod_fam $prod_name $sys_ven $board_name" | grep -qiE "ROG|TUF|ASUS|Strix|Zephyrus|Flow|Scar"
}

has_nvidia_gpu() {
    lspci 2>/dev/null | grep -qiE "(VGA|3D|Display).*NVIDIA" || \
    { command -v cardwire >/dev/null 2>&1 && cardwire list 2>/dev/null | grep -qi "NVIDIA"; } || \
    [[ -d /proc/driver/nvidia ]] || \
    [[ -d /sys/module/nvidia ]]
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

# ------------------------------------------------------------------------------
# Verification Routine
# ------------------------------------------------------------------------------
verify_profile() {
    echo -e "\n${BOLD}=== ASUS ROG + NVIDIA Power Status Check ===${NC}\n"

    # Hardware check
    local board prod
    board="$(cat /sys/class/dmi/id/board_name 2>/dev/null || echo 'Unknown')"
    prod="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')"
    log_info "Machine DMI: $prod (Board: $board)"

    if ! is_rog_machine; then
        log_warn "Host does not match ASUS ROG/TUF DMI signature."
    else
        log_success "Host matches ASUS ROG hardware profile."
    fi

    if ! has_nvidia_gpu; then
        log_warn "No NVIDIA discrete GPU found on this system."
    else
        log_success "NVIDIA GPU detected."
    fi

    # 1. Modprobe configuration
    local conf="/etc/modprobe.d/nvidia-power-management.conf"
    if [[ -f "$conf" ]]; then
        log_success "Modprobe config exists: $conf"
        grep -q "NVreg_TemporaryFilePath=/var/lib/systemd/sleep" "$conf" && \
            log_success "Temporary sleep path: /var/lib/systemd/sleep (SELinux standard)"
        grep -q "NVreg_DynamicPowerManagement=0x02" "$conf" && \
            log_success "DynamicPowerManagement: 0x02 (fine-grained D3cold)"
        grep -q "modeset=1" "$conf" && \
            log_success "nvidia-drm modeset: 1"
    else
        log_warn "Modprobe config NOT found at $conf"
    fi

    # 2. Kernel parameters
    if [[ -f /proc/driver/nvidia/params ]]; then
        local val
        val=$(grep "PreserveVideoMemoryAllocations:" /proc/driver/nvidia/params | awk '{print $2}')
        if [[ "$val" == "1" ]]; then
            log_success "Kernel parameter PreserveVideoMemoryAllocations is active: 1"
        else
            log_warn "Kernel parameter PreserveVideoMemoryAllocations is NOT 1 (current: $val)"
        fi
    fi
    if [[ -f /sys/module/nvidia/parameters/NVreg_DynamicPowerManagement ]]; then
        local dpm
        dpm=$(cat /sys/module/nvidia/parameters/NVreg_DynamicPowerManagement 2>/dev/null || echo "N/A")
        log_success "Active NVreg_DynamicPowerManagement: $dpm"
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

    # 4. Cardwire GPU management
    echo ""
    if command -v cardwire >/dev/null 2>&1; then
        log_info "Cardwire status:"
        cardwire get 2>/dev/null || true
        log_info "Cardwire GPU list:"
        cardwire list 2>/dev/null || true
    fi

    # 5. Power profiles & supply status
    echo ""
    log_info "Power Supply & Profile status:"
    if grep -qs 1 /sys/class/power_supply/*/online; then
        log_success "Power state: AC Connected"
    else
        log_info "Power state: Battery"
    fi
    if command -v powerprofilesctl >/dev/null 2>&1; then
        local prof
        prof=$(powerprofilesctl get 2>/dev/null || echo "N/A")
        log_success "Active Power Profile: $prof"
    fi

    # 6. Installed scripts and udev rules
    echo ""
    log_info "Checking installed automation files:"
    [[ -x /usr/local/bin/power-profile-switch.sh ]] && \
        log_success "Installed executable: /usr/local/bin/power-profile-switch.sh" || \
        log_warn "Missing /usr/local/bin/power-profile-switch.sh"
    [[ -f /etc/udev/rules.d/81-nvidia-pm-audio.rules ]] && \
        log_success "Installed udev rule: /etc/udev/rules.d/81-nvidia-pm-audio.rules" || \
        log_warn "Missing /etc/udev/rules.d/81-nvidia-pm-audio.rules"
    [[ -f /etc/udev/rules.d/99-laptop-power-dispatch.rules ]] && \
        log_success "Installed udev rule: /etc/udev/rules.d/99-laptop-power-dispatch.rules" || \
        log_warn "Missing /etc/udev/rules.d/99-laptop-power-dispatch.rules"
    echo ""
}

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    verify_profile
    exit 0
fi

# ------------------------------------------------------------------------------
# Main Installation Routine
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=== ASUS ROG + NVIDIA Hardware Profile Setup ===${NC}\n"

# Enforce hardware guard unless --force is given
if [[ "${1:-}" != "--force" ]]; then
    if ! is_rog_machine || ! has_nvidia_gpu; then
        log_info "Target hardware (ASUS ROG/TUF + NVIDIA dGPU) not detected on this system."
        log_info "Skipping hardware/rog-nvidia optimizations."
        exit 0
    fi
fi

log_success "Target hardware verified: ASUS ROG + NVIDIA dGPU detected."

# 1. Ensure /var/lib/systemd/sleep exists with secure permissions (SELinux standard)
log_info "Ensuring /var/lib/systemd/sleep exists..."
run_as_root mkdir -p /var/lib/systemd/sleep
run_as_root chmod 700 /var/lib/systemd/sleep
if command -v restorecon >/dev/null 2>&1; then
    run_as_root restorecon -v /var/lib/systemd/sleep || true
fi

# 2. Install modprobe configuration
CONF_SRC="$SCRIPT_DIR/nvidia-power-management.conf"
if [[ -f "$CONF_SRC" ]]; then
    log_info "Installing modprobe configuration..."
    run_as_root cp "$CONF_SRC" /etc/modprobe.d/nvidia-power-management.conf
    run_as_root chmod 644 /etc/modprobe.d/nvidia-power-management.conf
    log_success "Installed /etc/modprobe.d/nvidia-power-management.conf"
fi

# 3. Install Udev rules (Audio PM and Power Dispatcher)
if [[ -f "$SCRIPT_DIR/81-nvidia-pm-audio.rules" ]]; then
    log_info "Installing NVIDIA Audio PM udev rule..."
    run_as_root cp "$SCRIPT_DIR/81-nvidia-pm-audio.rules" /etc/udev/rules.d/81-nvidia-pm-audio.rules
    run_as_root chmod 644 /etc/udev/rules.d/81-nvidia-pm-audio.rules
    log_success "Installed /etc/udev/rules.d/81-nvidia-pm-audio.rules"
fi

if [[ -f "$SCRIPT_DIR/power-profile-switch.sh" ]]; then
    log_info "Installing power profile switcher..."
    run_as_root cp "$SCRIPT_DIR/power-profile-switch.sh" /usr/local/bin/power-profile-switch.sh
    run_as_root chmod 755 /usr/local/bin/power-profile-switch.sh
    log_success "Installed /usr/local/bin/power-profile-switch.sh"
fi

if [[ -f "$SCRIPT_DIR/99-laptop-power-dispatch.rules" ]]; then
    log_info "Installing AC/Battery power dispatch udev rule..."
    run_as_root cp "$SCRIPT_DIR/99-laptop-power-dispatch.rules" /etc/udev/rules.d/99-laptop-power-dispatch.rules
    run_as_root chmod 644 /etc/udev/rules.d/99-laptop-power-dispatch.rules
    log_success "Installed /etc/udev/rules.d/99-laptop-power-dispatch.rules"
fi

if command -v udevadm >/dev/null 2>&1; then
    log_info "Reloading udev rules..."
    run_as_root udevadm control --reload-rules || true
    run_as_root udevadm trigger --subsystem-match=pci || true
    run_as_root udevadm trigger --subsystem-match=power_supply || true
fi

# 4. Configure Cardwire daemon policies if installed
if command -v cardwire >/dev/null 2>&1; then
    log_info "Configuring Cardwire daemon auto-switching policies..."
    cardwire config battery-auto-switch true >/dev/null 2>&1 || true
    cardwire config battery-auto-switch-mode integrated >/dev/null 2>&1 || true
    cardwire config external-display-auto-switch true >/dev/null 2>&1 || true
    cardwire config save >/dev/null 2>&1 || true
    log_success "Cardwire auto-switch configured (Battery: Integrated, AC/Display: Auto)"
fi

# 5. Enable systemd sleep services
SERVICES=("nvidia-suspend.service" "nvidia-hibernate.service" "nvidia-resume.service")
if [[ -d /sys/module/nvidia ]] || systemctl list-unit-files nvidia-suspend.service &>/dev/null; then
    run_as_root systemctl daemon-reload
    for s in "${SERVICES[@]}"; do
        if systemctl list-unit-files "$s" &>/dev/null; then
            run_as_root systemctl enable "$s"
            log_success "Enabled systemd service: $s"
        else
            log_warn "Systemd unit $s not found (ensure NVIDIA driver/utils package is installed)"
        fi
    done
fi

# 6. Apply active power profile immediately
if [[ -x /usr/local/bin/power-profile-switch.sh ]]; then
    log_info "Applying active power profile switch..."
    run_as_root /usr/local/bin/power-profile-switch.sh || true
fi

# 7. Rebuild initramfs across all distros
rebuild_initramfs

# 8. Verify
verify_profile
