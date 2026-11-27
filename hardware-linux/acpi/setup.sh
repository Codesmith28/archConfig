#!/usr/bin/env bash
# ==============================================================================
# ACPI GPE, Interrupt & PCIe AER Storm Mitigation Setup
# Distro-agnostic (Fedora, Arch Linux, Ubuntu, OmArchy)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'
NC=$'\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }

run_as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo -e "${RED}[ERR]${NC}  Root privileges required. Run with sudo." >&2
        exit 1
    fi
}

detect_aer_storm() {
    local f total cor
    for f in /sys/bus/pci/devices/*/aer_dev_nonfatal; do
        [[ -r "$f" ]] || continue
        total="$(awk '/^TOTAL_ERR_NONFATAL/{print $2}' "$f" 2>/dev/null || echo 0)"
        if [[ "${total:-0}" -gt 0 ]]; then
            return 0
        fi
    done
    for f in /sys/bus/pci/devices/*/aer_rootport_total_err_cor; do
        [[ -r "$f" ]] || continue
        cor="$(cat "$f" 2>/dev/null || echo 0)"
        if [[ "${cor:-0}" -gt 10 ]]; then
            return 0
        fi
    done
    if command -v journalctl >/dev/null 2>&1; then
        local aer_lines
        aer_lines="$(journalctl -b 0 -k --no-pager 2>/dev/null | grep -c "PCIe Bus Error:.*UnsupReq" || true)"
        if [[ "${aer_lines:-0}" -gt 5 ]]; then
            return 0
        fi
    fi
    return 1
}

persist_kernel_arg() {
    local arg="$1"

    if command -v grubby >/dev/null 2>&1 && { [[ -d /boot/grub ]] || [[ -d /boot/grub2 ]] || command -v grub-mkconfig >/dev/null 2>&1 || command -v grub2-mkconfig >/dev/null 2>&1; }; then
        log_info "Injecting $arg into bootloader entries via grubby..."
        run_as_root grubby --update-kernel=ALL --args="$arg" 2>/dev/null || true
    fi

    if [[ -f /etc/default/grub ]]; then
        if grep -q "GRUB_CMDLINE_LINUX=" /etc/default/grub 2>/dev/null; then
            if ! grep -qw "$arg" /etc/default/grub 2>/dev/null; then
                log_info "Appending $arg to GRUB_CMDLINE_LINUX in /etc/default/grub..."
                run_as_root sed -i -E "s|^(GRUB_CMDLINE_LINUX=\"[^\"]*)(\")|\\1 ${arg}\\2|" /etc/default/grub
                if command -v update-grub >/dev/null 2>&1; then
                    run_as_root update-grub 2>/dev/null || true
                elif command -v grub-mkconfig >/dev/null 2>&1 && [[ -d /boot/grub ]]; then
                    run_as_root grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
                fi
            fi
        else
            echo "GRUB_CMDLINE_LINUX=\"$arg\"" | run_as_root tee -a /etc/default/grub >/dev/null
        fi
    fi

    if [[ -f /etc/kernel/cmdline ]] && ! grep -qw "$arg" /etc/kernel/cmdline 2>/dev/null; then
        log_info "Appending $arg to /etc/kernel/cmdline (BLS / systemd-boot)..."
        run_as_root sed -i -E "1s|[[:space:]]*$| ${arg}|" /etc/kernel/cmdline
    fi

    # Direct systemd-boot BLS entries (Arch/OmArchy/non-grubby setups)
    if [[ -d /boot/loader/entries ]] && ! command -v grubby >/dev/null 2>&1; then
        local entry
        for entry in /boot/loader/entries/*.conf; do
            [[ -f "$entry" ]] || continue
            if grep -q "^options " "$entry" 2>/dev/null && ! grep -qw "$arg" "$entry" 2>/dev/null; then
                log_info "Appending $arg to BLS entry $entry..."
                run_as_root sed -i -E "/^options / s|[[:space:]]*$| ${arg}|" "$entry"
            fi
        done
    fi
}

verify_acpi() {
    echo -e "\n${BOLD}=== ACPI & PCIe AER Storm Guard Status ===${NC}\n"

    if [[ -x /usr/local/bin/acpi-storm-guard.sh ]]; then
        log_success "Installed executable: /usr/local/bin/acpi-storm-guard.sh"
    else
        log_warn "Missing /usr/local/bin/acpi-storm-guard.sh"
    fi

    local svc_state
    svc_state="$(systemctl is-enabled acpi-storm-guard.service 2>/dev/null || true)"
    svc_state="${svc_state:-not-found}"
    if [[ "$svc_state" == "enabled" ]]; then
        log_success "Unit acpi-storm-guard.service: $svc_state"
    else
        log_warn "Unit acpi-storm-guard.service: $svc_state"
    fi

    if [[ -x /usr/lib/systemd/system-sleep/acpi-storm-guard.sh ]] || [[ -x /etc/systemd/system-sleep/acpi-storm-guard.sh ]]; then
        log_success "Installed sleep resume hook: acpi-storm-guard.sh"
    else
        log_warn "Missing system-sleep hook: acpi-storm-guard.sh"
    fi

    if grep -qw "pci=noaer" /proc/cmdline 2>/dev/null; then
        log_success "Kernel cmdline: pci=noaer active"
    elif detect_aer_storm; then
        log_warn "Active PCIe AER UnsupReq/Correctable error storm detected; pci=noaer not active in current boot"
    else
        log_info "Kernel cmdline: pci=noaer not set (no active AER storm detected)"
    fi

    if [[ -f /etc/default/grub ]] && grep -qw "pci=noaer" /etc/default/grub 2>/dev/null; then
        log_success "GRUB_CMDLINE_LINUX: pci=noaer configured"
    fi
    if [[ -f /etc/kernel/cmdline ]] && grep -qw "pci=noaer" /etc/kernel/cmdline 2>/dev/null; then
        log_success "BLS /etc/kernel/cmdline: pci=noaer configured"
    fi

    echo ""
    bash "$SCRIPT_DIR/acpi-storm-guard.sh" --verify || true
}

FORCE_NOAER=0
for arg in "$@"; do
    case "$arg" in
        --verify|-v|verify|status)
            verify_acpi
            exit 0
            ;;
        --force-noaer)
            FORCE_NOAER=1
            ;;
    esac
done

echo -e "\n${BOLD}=== ACPI & PCIe AER Storm Guard Setup ===${NC}\n"

SLEEP_DEST="/usr/lib/systemd/system-sleep"
[[ -d "$SLEEP_DEST" ]] || SLEEP_DEST="/etc/systemd/system-sleep"

run_as_root mkdir -p /usr/local/bin /etc/systemd/system "$SLEEP_DEST"

log_info "Installing acpi-storm-guard.sh to /usr/local/bin/..."
run_as_root cp -f "$SCRIPT_DIR/acpi-storm-guard.sh" /usr/local/bin/acpi-storm-guard.sh
run_as_root chmod 755 /usr/local/bin/acpi-storm-guard.sh

log_info "Installing acpi-storm-guard.service to /etc/systemd/system/..."
run_as_root cp -f "$SCRIPT_DIR/acpi-storm-guard.service" /etc/systemd/system/acpi-storm-guard.service
run_as_root chmod 644 /etc/systemd/system/acpi-storm-guard.service

log_info "Installing sleep resume hook to $SLEEP_DEST/acpi-storm-guard.sh..."
run_as_root cp -f "$SCRIPT_DIR/acpi-storm-sleep.sh" "$SLEEP_DEST/acpi-storm-guard.sh"
run_as_root chmod 755 "$SLEEP_DEST/acpi-storm-guard.sh"

if command -v systemctl >/dev/null 2>&1; then
    run_as_root systemctl daemon-reload 2>/dev/null || true
    run_as_root systemctl enable --now acpi-storm-guard.service 2>/dev/null || true
    log_success "acpi-storm-guard.service enabled and started."
fi

if [[ "$FORCE_NOAER" -eq 1 ]] || detect_aer_storm; then
    log_info "PCIe AER UnsupReq/Correctable error storm detected; persisting pci=noaer..."
    persist_kernel_arg "pci=noaer"
    log_success "pci=noaer configured in bootloader (takes effect on next reboot)."
else
    log_info "No active PCIe AER storm detected; skipping pci=noaer."
fi

verify_acpi
