#!/usr/bin/env bash
# ==============================================================================
# Ubuntu GRUB Graphical Terminal & High-Resolution Setup
# ==============================================================================
# Configures GRUB to use UEFI GOP automatic native resolution via gfxterm,
# ensures smooth kernel handoff, and repairs corrupted GRUB configuration
# entries without hardcoding resolution numbers or injecting custom font overrides.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/common.sh"
else
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
            log_error "Root privileges required. Please run with sudo or as root."
            exit 1
        fi
    }
fi

GRUB_FILE="/etc/default/grub"
GRUB_BOOT_DIR="/boot/grub"
# ------------------------------------------------------------------------------
# Verify GRUB Status
# ------------------------------------------------------------------------------
verify_grub() {
    echo -e "\n${BOLD}=== GRUB Resolution Status Check (Ubuntu) ===${NC}\n"

    if [[ ! -f "$GRUB_FILE" ]]; then
        log_error "GRUB configuration file not found at $GRUB_FILE"
        return 1
    fi

    local term
    term=$(grep "^[[:space:]]*GRUB_TERMINAL_OUTPUT=" "$GRUB_FILE" 2>/dev/null || echo "")
    if [[ "$term" =~ gfxterm ]]; then
        log_success "Terminal output: ${BOLD}${term}${NC} (graphical GOP mode enabled)"
    else
        log_warn "Terminal output: ${BOLD}${term:-none (defaulting to text console mode)}${NC}"
    fi

    local gfxmode
    gfxmode=$(grep "^[[:space:]]*GRUB_GFXMODE=" "$GRUB_FILE" 2>/dev/null || echo "")
    local gfx_val
    gfx_val="$(echo "$gfxmode" | cut -d= -f2- | tr -d '"'"'")"
    if [[ "$gfx_val" == "auto" ]]; then
        log_success "GFXMODE Setting: ${BOLD}${gfxmode}${NC} (native UEFI GOP auto-resolution active)"
    elif [[ -n "$gfxmode" ]]; then
        log_warn "GFXMODE Setting: ${BOLD}${gfxmode}${NC} (legacy hardcoded list; recommend GRUB_GFXMODE=\"auto\")"
    else
        log_success "GFXMODE Setting: ${BOLD}none (defaults to native UEFI GOP auto-resolution)${NC}"
    fi

    local payload
    payload=$(grep "^[[:space:]]*GRUB_GFXPAYLOAD_LINUX=" "$GRUB_FILE" 2>/dev/null || echo "")
    if [[ "$payload" =~ keep ]]; then
        log_success "Kernel Payload : ${BOLD}${payload}${NC} (smooth handoff without mode switch)"
    else
        log_warn "Kernel Payload : ${BOLD}${payload:-none}${NC}"
    fi

    local font_entry
    font_entry=$(grep "^[[:space:]]*GRUB_FONT=" "$GRUB_FILE" 2>/dev/null || echo "")
    if [[ -n "$font_entry" ]]; then
        local font_path
        font_path="$(echo "$font_entry" | cut -d= -f2- | tr -d '"'"'")"
        if [[ "$font_path" =~ [[:cntrl:]] ]] || [[ "$font_path" =~ \[[0-9]+m ]] || [[ "$font_entry" =~ Compiling ]] || [[ "$font_entry" =~ \[INFO\] ]]; then
            log_error "Configured font: ${BOLD}Corrupted multiline entry in ${GRUB_FILE}!${NC}"
        elif [[ -f "$font_path" ]]; then
            log_warn "Configured font: ${BOLD}${font_entry}${NC} (custom font override active)"
        else
            log_error "Configured font: ${BOLD}${font_entry}${NC} (file missing on disk!)"
        fi
    else
        log_success "Font rendering : ${BOLD}native UEFI GOP (clean, no custom GRUB_FONT override)${NC}"
    fi

    echo ""
}

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Ubuntu GRUB Graphical Terminal & High-Resolution Setup
Configures UEFI GOP native high-resolution boot via gfxterm without hardcoded resolution numbers.

Options:
  -v, --verify, status    Check and report current GRUB configuration without modifying anything
  -h, --help, help        Show this help message and exit

Examples:
  ./$(basename "$0") --verify
  sudo ./$(basename "$0")
EOF
}

# Check for help invocation
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "help" ]]; then
    show_help
    exit 0
fi

# Check for verification / status invocation
if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    verify_grub
    exit 0
fi

if [[ ! -f "$GRUB_FILE" ]]; then
    log_error "GRUB configuration file not found at $GRUB_FILE"
    exit 1
fi

log_info "Configuring Ubuntu GRUB for native UEFI GOP auto-resolution..."

has_root=0
if [[ "$(id -u)" -eq 0 ]]; then
    has_root=1
elif sudo -n true 2>/dev/null; then
    has_root=1
fi

if [[ $has_root -eq 0 ]]; then
    log_warn "Running without root privileges. Checking current GRUB configuration:"
    verify_grub
    log_info "To apply clean UEFI GOP high-resolution configuration and regenerate bootloader, run:"
    log_info "  ${BOLD}sudo ./setup.sh${NC}"
    exit 0
fi

# 1. Create timestamped backup of current GRUB configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${GRUB_FILE}.bak.${TIMESTAMP}"
log_info "Creating backup at ${BACKUP_FILE}..."
run_as_root cp "$GRUB_FILE" "$BACKUP_FILE"

# 2. Clean up any corrupted multiline or ANSI-polluted GRUB_FONT entries
run_as_root sed -i -E '/^[[:space:]]*GRUB_FONT=/d' "$GRUB_FILE"
run_as_root sed -i -E '/\[INFO\].*font/d' "$GRUB_FILE"
run_as_root sed -i -E '/\[OK\].*font/d' "$GRUB_FILE"
run_as_root sed -i -E '/Compiling.*font/d' "$GRUB_FILE"
run_as_root sed -i -E '/Generated.*font/d' "$GRUB_FILE"
run_as_root sed -i -E '/\/boot\/grub.*\.pf2/d' "$GRUB_FILE"

# 3. Helper to update key=value in /etc/default/grub
set_grub_kv() {
    local key="$1"
    local val="$2"
    if grep -q "^[#[:space:]]*${key}=" "$GRUB_FILE"; then
        run_as_root sed -i -E "s|^[#[:space:]]*${key}=.*|${key}=\"${val}\"|" "$GRUB_FILE"
    else
        echo "${key}=\"${val}\"" | run_as_root tee -a "$GRUB_FILE" >/dev/null
    fi
}

# Disable any legacy GRUB_TERMINAL=console
if grep -q "^[[:space:]]*GRUB_TERMINAL=" "$GRUB_FILE"; then
    run_as_root sed -i -E 's|^[[:space:]]*GRUB_TERMINAL=.*|# & (disabled in favor of GRUB_TERMINAL_OUTPUT="gfxterm")|' "$GRUB_FILE"
fi

set_grub_kv "GRUB_TERMINAL_OUTPUT" "gfxterm"
set_grub_kv "GRUB_GFXMODE" "auto"
set_grub_kv "GRUB_GFXPAYLOAD_LINUX" "keep"

log_info "Changes applied to ${GRUB_FILE}:"
diff -u "$BACKUP_FILE" "$GRUB_FILE" || true

log_info "Running update-grub..."
if run_as_root update-grub; then
    log_success "GRUB updated successfully with UEFI GOP auto-resolution!"
    log_info "Backup preserved at: ${BACKUP_FILE}"
else
    log_error "update-grub failed! Rolling back changes..."
    run_as_root cp "$BACKUP_FILE" "$GRUB_FILE"
    log_warn "Original configuration restored."
    exit 1
fi

verify_grub
log_success "Ubuntu GRUB high-resolution setup finished successfully!"
