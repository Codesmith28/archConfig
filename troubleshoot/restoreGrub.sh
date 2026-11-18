#!/usr/bin/env bash
# ==============================================================================
# Universal Multi-Distro GRUB Bootloader & High-Resolution Restoration Tool
# Supports: Fedora, Arch Linux, Ubuntu / Debian
# ==============================================================================
# Restores EFI bootloader entries, repairs dual-boot, enables native UEFI GOP
# high-resolution display mode via gfxterm without hardcoding resolution numbers,
# and ensures smooth kernel handoff.
# ==============================================================================
set -euo pipefail

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
NC=$'\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*" >&2; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error()   { echo -e "${RED}[ERR]${NC}  $*" >&2; }

run_as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        log_error "This operation requires root privileges, but sudo is unavailable."
        return 1
    fi
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "${ID:-}" in
            fedora) echo "fedora" ;;
            arch|endeavouros|manjaro) echo "arch" ;;
            ubuntu|pop|linuxmint|debian) echo "ubuntu" ;;
            *)
                if [[ "${ID_LIKE:-}" =~ (fedora|rhel) ]]; then echo "fedora";
                elif [[ "${ID_LIKE:-}" =~ arch ]]; then echo "arch";
                elif [[ "${ID_LIKE:-}" =~ (ubuntu|debian) ]]; then echo "ubuntu";
                else echo "generic"; fi
                ;;
        esac
    else
        echo "generic"
    fi
}

verify_grub() {
    local grub_file="/etc/default/grub"
    echo ""
    echo -e "${BOLD}=== GRUB Multi-Distro Status Check ===${NC}"
    echo -e "Detected Distro     : ${CYAN}$(detect_distro)${NC}"

    if [[ ! -f "$grub_file" ]]; then
        log_error "Config file $grub_file not found."
        return 1
    fi

    local term gfx payload font
    term="$(grep -E '^[[:space:]]*GRUB_TERMINAL_OUTPUT=' "$grub_file" | tail -n 1 | cut -d= -f2- | tr -d '"' || true)"
    gfx="$(grep -E '^[[:space:]]*GRUB_GFXMODE=' "$grub_file" | tail -n 1 | cut -d= -f2- | tr -d '"' || true)"
    payload="$(grep -E '^[[:space:]]*GRUB_GFXPAYLOAD_LINUX=' "$grub_file" | tail -n 1 | cut -d= -f2- | tr -d '"' || true)"
    font="$(grep -E '^[[:space:]]*GRUB_FONT=' "$grub_file" | tail -n 1 | cut -d= -f2- | tr -d '"' || true)"

    if [[ "$term" == "gfxterm" ]]; then
        log_success "Terminal Output: $term (graphical GOP mode enabled)"
    else
        log_warn "Terminal Output: ${term:-none} (Recommended: gfxterm)"
    fi

    if [[ "$gfx" == "auto" ]]; then
        log_success "GFXMODE Setting: $gfx (native UEFI GOP auto-resolution active)"
    elif [[ -n "$gfx" ]]; then
        log_warn "GFXMODE Setting: $gfx (legacy hardcoded list; recommend GRUB_GFXMODE=\"auto\")"
    else
        log_success "GFXMODE Setting: none (defaults to native UEFI GOP auto-resolution)"
    fi

    if [[ "$payload" == "keep" ]]; then
        log_success "Kernel Payload : $payload (smooth handoff without mode switch)"
    else
        log_warn "Kernel Payload : ${payload:-none} (Recommended: keep)"
    fi

    local raw_font_entry
    raw_font_entry="$(grep "^[[:space:]]*GRUB_FONT=" "$grub_file" 2>/dev/null || echo "")"
    if [[ -n "$font" ]]; then
        if [[ "$font" =~ [[:cntrl:]] ]] || [[ "$font" =~ \[[0-9]+m ]] || [[ "$raw_font_entry" =~ Compiling ]] || [[ "$raw_font_entry" =~ \[INFO\] ]]; then
            log_error "Configured Font: Corrupted multiline entry in $grub_file!"
        elif [[ -f "$font" ]]; then
            log_warn "Configured Font: $font (custom font override active)"
        else
            log_error "Configured Font: $font (file missing on disk!)"
        fi
    else
        log_success "Font Rendering : native UEFI GOP (clean, no custom GRUB_FONT override)"
    fi
    echo ""
}

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Universal Multi-Distro GRUB Bootloader & High-Resolution Restoration Tool
Supports: Fedora, Arch Linux, Ubuntu / Debian

Options:
  -v, --verify, status    Check and report current GRUB configuration without modifying anything
  -c, --config-only       Update /etc/default/grub with clean UEFI GOP auto-resolution and regenerate grub.cfg
  -i, --install           Reinstall GRUB EFI bootloader binaries and regenerate configuration
  -p, --enable-os-prober  Enable GRUB_DISABLE_OS_PROBER=false for dual-boot Windows detection
  -h, --help, help        Show this help message and exit

Examples:
  ./$(basename "$0") --verify
  sudo ./$(basename "$0") --config-only
  sudo ./$(basename "$0") --install
EOF
}

MODE="full"
ENABLE_OS_PROBER=0

for arg in "$@"; do
    case "$arg" in
        --help|-h|help)
            show_help
            exit 0
            ;;
        --verify|-v|status)     MODE="verify" ;;
        --config-only|-c)       MODE="config" ;;
        --install|-i)           MODE="install" ;;
        --enable-os-prober|-p) ENABLE_OS_PROBER=1 ;;
    esac
done

if [[ "$MODE" == "verify" ]]; then
    verify_grub
    exit 0
fi

DISTRO="$(detect_distro)"
GRUB_FILE="/etc/default/grub"

log_info "Running GRUB restoration and UEFI GOP high-res setup for ${BOLD}${DISTRO}${NC}..."

# Check root permissions
if [[ "$(id -u)" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
        log_error "Root privileges or sudo required to modify bootloader."
        exit 1
    fi
fi

# Determine boot directory
BOOT_DIR="/boot/grub"
if [[ "$DISTRO" == "fedora" ]] || [[ -d /boot/grub2 ]]; then
    BOOT_DIR="/boot/grub2"
fi

# 1. Install missing bootloader packages if in install/full mode
if [[ "$MODE" == "install" || "$MODE" == "full" ]]; then
    log_info "Ensuring GRUB & EFI boot utilities are installed..."
    case "$DISTRO" in
        arch)
            if command -v pacman >/dev/null 2>&1; then
                run_as_root pacman -Sy --noconfirm --needed grub efibootmgr dosfstools mtools os-prober || true
            fi
            ;;
        fedora)
            if command -v dnf >/dev/null 2>&1; then
                run_as_root dnf install -y grub2-tools grub2-tools-extra efibootmgr os-prober || true
            fi
            ;;
        ubuntu)
            if command -v apt-get >/dev/null 2>&1; then
                run_as_root apt-get update -qq || true
                run_as_root apt-get install -y -qq grub-efi-amd64-bin grub2-common efibootmgr os-prober || true
            fi
            ;;
    esac
fi

# 2. Update /etc/default/grub (with backup first)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${GRUB_FILE}.bak.${TIMESTAMP}"
log_info "Creating backup at ${BACKUP_FILE}..."
run_as_root cp "$GRUB_FILE" "$BACKUP_FILE"

# Clean up any corrupted multiline or ANSI-polluted GRUB_FONT entries from /etc/default/grub
run_as_root sed -i -E '/^[[:space:]]*GRUB_FONT=/d' "$GRUB_FILE"
run_as_root sed -i -E '/\[INFO\].*font/d' "$GRUB_FILE"
run_as_root sed -i -E '/\[OK\].*font/d' "$GRUB_FILE"
run_as_root sed -i -E '/Compiling.*font/d' "$GRUB_FILE"
run_as_root sed -i -E '/Generated.*font/d' "$GRUB_FILE"
run_as_root sed -i -E '/\/boot\/grub.*\.pf2/d' "$GRUB_FILE"

set_grub_kv() {
    local key="$1"
    local val="$2"
    if grep -q "^[#[:space:]]*${key}=" "$GRUB_FILE"; then
        run_as_root sed -i -E "s|^[#[:space:]]*${key}=.*|${key}=\"${val}\"|" "$GRUB_FILE"
    else
        echo "${key}=\"${val}\"" | run_as_root tee -a "$GRUB_FILE" >/dev/null
    fi
}

set_grub_kv "GRUB_TERMINAL_OUTPUT" "gfxterm"
set_grub_kv "GRUB_GFXMODE" "auto"
set_grub_kv "GRUB_GFXPAYLOAD_LINUX" "keep"

if [[ $ENABLE_OS_PROBER -eq 1 ]]; then
    set_grub_kv "GRUB_DISABLE_OS_PROBER" "false"
    log_info "Enabled dual-boot OS prober (GRUB_DISABLE_OS_PROBER=\"false\")."
fi

# Disable conflicting console terminal output
if grep -q "^[[:space:]]*GRUB_TERMINAL=" "$GRUB_FILE"; then
    run_as_root sed -i -E 's|^[[:space:]]*GRUB_TERMINAL=.*|# & (disabled in favor of GRUB_TERMINAL_OUTPUT="gfxterm")|' "$GRUB_FILE"
fi

log_success "Updated ${GRUB_FILE} with UEFI GOP auto-resolution gfxterm configuration."

# 3. Bootloader reinstallation (if requested and in EFI environment)
if [[ "$MODE" == "install" ]]; then
    EFI_DIR="/boot/efi"
    if [[ -d "$EFI_DIR" && -d /sys/firmware/efi ]]; then
        log_info "Reinstalling GRUB EFI bootloader..."
        if command -v grub-install >/dev/null 2>&1; then
            run_as_root grub-install --target=x86_64-efi --efi-directory="$EFI_DIR" --bootloader-id=GRUB --recheck || true
        elif command -v grub2-install >/dev/null 2>&1; then
            run_as_root grub2-install --target=x86_64-efi --efi-directory="$EFI_DIR" --bootloader-id=Fedora --recheck || true
        fi
    fi
fi

# 4. Regenerate GRUB configuration
log_info "Regenerating GRUB configuration..."
if command -v grub2-mkconfig >/dev/null 2>&1; then
    run_as_root mkdir -p "$BOOT_DIR"
    run_as_root grub2-mkconfig -o "$BOOT_DIR/grub.cfg"
    if [[ -f /etc/grub2.cfg && ! -L /etc/grub2.cfg ]]; then
        run_as_root cp "$BOOT_DIR/grub.cfg" /etc/grub2.cfg
    fi
elif command -v grub-mkconfig >/dev/null 2>&1; then
    run_as_root mkdir -p "$BOOT_DIR"
    run_as_root grub-mkconfig -o "$BOOT_DIR/grub.cfg"
elif command -v update-grub >/dev/null 2>&1; then
    run_as_root update-grub
fi

log_success "GRUB restoration and high-res configuration complete!"
verify_grub
