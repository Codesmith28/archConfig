#!/usr/bin/env bash
# ==============================================================================
# GRUB Graphical Terminal Setup (Fedora)
# ==============================================================================
# Enables GRUB_TERMINAL_OUTPUT="gfxterm", which allows UEFI GOP to automatically
# select the best native display resolution without hardcoding or manual probing.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

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

GRUB_FILE="/etc/default/grub"
TARGET_FONT="/boot/grub2/fonts/unicode.pf2"
SOURCE_FONT="/usr/share/grub/unicode.pf2"

verify_grub() {
    echo -e "\n${BOLD}=== GRUB Graphical Terminal Status Check ===${NC}\n"

    if [[ ! -f "$GRUB_FILE" ]]; then
        log_error "GRUB configuration file not found at $GRUB_FILE"
        return 1
    fi

    # Check GRUB_TERMINAL_OUTPUT
    term=$(grep "^[[:space:]]*GRUB_TERMINAL_OUTPUT=" "$GRUB_FILE" 2>/dev/null || echo "")
    if [[ "$term" =~ gfxterm ]]; then
        log_success "Terminal output: ${BOLD}${term}${NC} (automatic best resolution enabled)"
    else
        log_warn "Terminal output: ${BOLD}${term:-none (defaulting to console text mode)}${NC}"
    fi

    # Check that manual GFXMODE attempts are cleaned up
    gfxmode=$(grep "^[[:space:]]*GRUB_GFXMODE=" "$GRUB_FILE" 2>/dev/null || echo "")
    if [[ -n "$gfxmode" ]]; then
        log_info "Legacy GFXMODE setting present: ${gfxmode}"
    else
        log_success "No hardcoded GFXMODE (native UEFI GOP auto-resolution active)"
    fi

    # Check Font
    font_entry=$(grep "^[[:space:]]*GRUB_FONT=" "$GRUB_FILE" 2>/dev/null || echo "")
    if [[ "$font_entry" =~ $TARGET_FONT ]]; then
        log_success "Configured font: ${BOLD}${font_entry}${NC}"
    else
        log_warn "Configured font: ${BOLD}${font_entry:-none}${NC}"
    fi

    echo ""
}

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    verify_grub
    exit 0
fi

log_info "Configuring GRUB graphical terminal (gfxterm) for automatic native resolution..."

has_root=0
if [[ "$(id -u)" -eq 0 ]]; then
    has_root=1
elif sudo -n true 2>/dev/null; then
    has_root=1
fi

if [[ $has_root -eq 0 ]]; then
    log_warn "Running without root privileges. Checking current GRUB configuration:"
    verify_grub
    log_info "To apply gfxterm configuration and regenerate bootloader, run:"
    log_info "  ${BOLD}sudo ./setup.sh${NC} (or ${BOLD}sudo ../setup.sh config_grub${NC})"
    exit 0
fi

# 1. Clean up prior attempts (manual GFXMODE, stale backups, duplicate entries)
log_info "Cleaning up prior manual resolution attempts from ${GRUB_FILE}..."
run_as_root sed -i -E '/^[[:space:]]*GRUB_GFXMODE=/d' "$GRUB_FILE"
run_as_root sed -i -E '/^[[:space:]]*GRUB_GFXPAYLOAD_LINUX=/d' "$GRUB_FILE"
run_as_root sed -i -E '/^[[:space:]]*GRUB_FONT=/d' "$GRUB_FILE"

for old_bak in /etc/default/grub.bak.*; do
    if [[ -f "$old_bak" ]]; then
        run_as_root rm -f "$old_bak"
    fi
done

# 2. Set GRUB_TERMINAL_OUTPUT to gfxterm (replaces console)
if grep -q "^[#[:space:]]*GRUB_TERMINAL_OUTPUT=" "$GRUB_FILE"; then
    run_as_root sed -i 's|^[#[:space:]]*GRUB_TERMINAL_OUTPUT=.*|GRUB_TERMINAL_OUTPUT="gfxterm"|' "$GRUB_FILE"
else
    echo 'GRUB_TERMINAL_OUTPUT="gfxterm"' | run_as_root tee -a "$GRUB_FILE" >/dev/null
fi

# Disable any legacy GRUB_TERMINAL=console
if grep -q "^[[:space:]]*GRUB_TERMINAL=" "$GRUB_FILE"; then
    run_as_root sed -i 's|^[[:space:]]*GRUB_TERMINAL=.*|# & (disabled in favor of GRUB_TERMINAL_OUTPUT="gfxterm")|' "$GRUB_FILE"
fi

# 3. Configure font directive for gfxterm
echo "GRUB_FONT=\"${TARGET_FONT}\"" | run_as_root tee -a "$GRUB_FILE" >/dev/null

log_success "Updated ${GRUB_FILE} with GRUB_TERMINAL_OUTPUT=\"gfxterm\"."

# 4. Provision unicode font in /boot/grub2/fonts/
if [[ -f "$SOURCE_FONT" ]]; then
    run_as_root mkdir -p "$(dirname "$TARGET_FONT")"
    run_as_root cp "$SOURCE_FONT" "$TARGET_FONT"
    run_as_root chmod 644 "$TARGET_FONT"
    log_success "Provisioned GRUB unicode font at ${TARGET_FONT}"
fi

# 5. Regenerate GRUB bootloader configuration
log_info "Regenerating GRUB bootloader configuration..."
if command -v grub2-mkconfig >/dev/null 2>&1; then
    run_as_root grub2-mkconfig -o /etc/grub2.cfg
    log_success "GRUB configuration regenerated successfully (/etc/grub2.cfg -> /boot/grub2/grub.cfg)!"
elif command -v update-grub >/dev/null 2>&1; then
    run_as_root update-grub
    log_success "GRUB configuration regenerated successfully via update-grub!"
fi

# 6. Verify result
verify_grub
log_success "GRUB gfxterm setup completed successfully!"
