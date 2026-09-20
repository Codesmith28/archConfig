#!/usr/bin/env bash
# ==============================================================================
# GRUB Configuration & Resolution Setup (Fedora / Ubuntu / Arch)
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

# Detect or parse desired screen resolution.
# If $1 is passed and is a valid resolution format (e.g. 1920x1200, 1920x1080, auto, 1920x1200,auto),
# use it. Ignore directory paths (like /usr/local/bin passed by the master setup.sh).
RESOLUTION=""
if [[ -n "${1:-}" && ! "$1" =~ ^/ && ! -d "$1" && "$1" =~ ^([0-9]+x[0-9]+|auto) ]]; then
    RESOLUTION="$1"
elif [[ -n "${GRUB_RESOLUTION:-}" ]]; then
    RESOLUTION="$GRUB_RESOLUTION"
else
    # Auto-detect native resolution from DRM modes if available, fallback to 1920x1200,auto
    DETECTED_RES=""
    if compgen -G "/sys/class/drm/*/modes" >/dev/null 2>&1; then
        DETECTED_RES=$(cat /sys/class/drm/*/modes 2>/dev/null | grep -E '^[0-9]+x[0-9]+$' | head -n 1 || true)
    fi
    if [[ -n "$DETECTED_RES" ]]; then
        RESOLUTION="${DETECTED_RES},auto"
    else
        RESOLUTION="1920x1200,auto"
    fi
fi

GRUB_FILE="/etc/default/grub"

if [[ ! -f "$GRUB_FILE" ]]; then
    log_error "GRUB configuration file not found at $GRUB_FILE"
    exit 1
fi

# 1. Ensure unicode font is installed into /boot/grub2/fonts/ so gfxterm can render graphics
font_installed=0
if [[ -f "/usr/share/grub/unicode.pf2" ]]; then
    if [[ ! -f "/boot/grub2/fonts/unicode.pf2" ]]; then
        log_info "Ensuring GRUB unicode font is available in /boot/grub2/fonts/..."
        run_as_root mkdir -p /boot/grub2/fonts
        run_as_root cp "/usr/share/grub/unicode.pf2" "/boot/grub2/fonts/unicode.pf2"
        font_installed=1
    fi
fi

target_terminal='GRUB_TERMINAL_OUTPUT="gfxterm"'
target_gfxmode="GRUB_GFXMODE=\"${RESOLUTION}\""
target_gfxpayload='GRUB_GFXPAYLOAD_LINUX="keep"'
target_font='GRUB_FONT="/boot/grub2/fonts/unicode.pf2"'

# 2. Check current configuration in /etc/default/grub
current_terminal=$(grep "^[[:space:]]*GRUB_TERMINAL_OUTPUT=" "$GRUB_FILE" 2>/dev/null || true)
current_terminal_legacy=$(grep "^[[:space:]]*GRUB_TERMINAL=" "$GRUB_FILE" 2>/dev/null || true)
current_gfxmode=$(grep "^[[:space:]]*GRUB_GFXMODE=" "$GRUB_FILE" 2>/dev/null || true)
current_gfxpayload=$(grep "^[[:space:]]*GRUB_GFXPAYLOAD_LINUX=" "$GRUB_FILE" 2>/dev/null || true)
current_font=$(grep "^[[:space:]]*GRUB_FONT=" "$GRUB_FILE" 2>/dev/null || true)

needs_update=0
if [[ "$current_terminal" != "$target_terminal" ]]; then needs_update=1; fi
if [[ -n "$current_terminal_legacy" && "$current_terminal_legacy" != *"gfxterm"* ]]; then needs_update=1; fi
if [[ "$current_gfxmode" != "$target_gfxmode" ]]; then needs_update=1; fi
if [[ "$current_gfxpayload" != "$target_gfxpayload" ]]; then needs_update=1; fi
if [[ -f "/boot/grub2/fonts/unicode.pf2" && "$current_font" != "$target_font" ]]; then needs_update=1; fi
if [[ "$font_installed" -eq 1 ]]; then needs_update=1; fi

if [[ "${1:-}" == "--force" || "${2:-}" == "--force" || "${FORCE:-0}" == "1" ]]; then
    needs_update=1
fi

if [[ $needs_update -eq 0 ]]; then
    log_info "GRUB configuration at ${GRUB_FILE} already has the desired settings:"
    log_info "  - ${target_terminal}"
    log_info "  - ${target_gfxmode}"
    log_info "  - ${target_gfxpayload}"
    [[ -n "$current_font" ]] && log_info "  - ${current_font}"
    log_success "Original GRUB configuration is intact and up to date."
    exit 0
fi

log_info "Configuring GRUB graphical output (gfxterm) and resolution (${RESOLUTION})..."

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${GRUB_FILE}.bak.${TIMESTAMP}"

log_info "Creating backup at ${BACKUP_FILE}..."
run_as_root cp "$GRUB_FILE" "$BACKUP_FILE"

# 3. Apply configurations preserving all other distro defaults untouched
# Replace or append GRUB_TERMINAL_OUTPUT="gfxterm" (critical on Fedora which defaults to "console")
if grep -q "^[#[:space:]]*GRUB_TERMINAL_OUTPUT=" "$GRUB_FILE"; then
    run_as_root sed -i "s|^[#[:space:]]*GRUB_TERMINAL_OUTPUT=.*|${target_terminal}|" "$GRUB_FILE"
else
    echo "${target_terminal}" | run_as_root tee -a "$GRUB_FILE" >/dev/null
fi

# Disable conflicting GRUB_TERMINAL=console if present
if grep -q "^[[:space:]]*GRUB_TERMINAL=" "$GRUB_FILE"; then
    run_as_root sed -i "s|^[[:space:]]*GRUB_TERMINAL=.*|# & (disabled in favor of GRUB_TERMINAL_OUTPUT)|" "$GRUB_FILE"
fi

# Replace or append GRUB_GFXMODE
if grep -q "^[#[:space:]]*GRUB_GFXMODE=" "$GRUB_FILE"; then
    run_as_root sed -i "s|^[#[:space:]]*GRUB_GFXMODE=.*|${target_gfxmode}|" "$GRUB_FILE"
else
    echo "${target_gfxmode}" | run_as_root tee -a "$GRUB_FILE" >/dev/null
fi

# Replace or append GRUB_GFXPAYLOAD_LINUX
if grep -q "^[#[:space:]]*GRUB_GFXPAYLOAD_LINUX=" "$GRUB_FILE"; then
    run_as_root sed -i "s|^[#[:space:]]*GRUB_GFXPAYLOAD_LINUX=.*|${target_gfxpayload}|" "$GRUB_FILE"
else
    echo "${target_gfxpayload}" | run_as_root tee -a "$GRUB_FILE" >/dev/null
fi

# Set GRUB_FONT if unicode font is present
if [[ -f "/boot/grub2/fonts/unicode.pf2" ]]; then
    if grep -q "^[#[:space:]]*GRUB_FONT=" "$GRUB_FILE"; then
        run_as_root sed -i "s|^[#[:space:]]*GRUB_FONT=.*|${target_font}|" "$GRUB_FILE"
    else
        echo "${target_font}" | run_as_root tee -a "$GRUB_FILE" >/dev/null
    fi
fi

echo ""
log_info "Changes applied to ${GRUB_FILE}:"
diff -u "$BACKUP_FILE" "$GRUB_FILE" || true
echo ""

update_grub_config() {
    if command -v grub2-mkconfig >/dev/null 2>&1; then
        local target_cfg="/boot/grub2/grub.cfg"
        log_info "Running grub2-mkconfig -o ${target_cfg}..."
        run_as_root grub2-mkconfig -o "${target_cfg}"
    elif command -v update-grub >/dev/null 2>&1; then
        log_info "Running update-grub..."
        run_as_root update-grub
    elif command -v grub-mkconfig >/dev/null 2>&1; then
        local target_cfg="/boot/grub/grub.cfg"
        log_info "Running grub-mkconfig -o ${target_cfg}..."
        run_as_root grub-mkconfig -o "${target_cfg}"
    else
        log_error "No supported GRUB update tool found (grub2-mkconfig, update-grub, or grub-mkconfig)."
        return 1
    fi
}

log_info "Updating bootloader configuration..."
if update_grub_config; then
    log_success "GRUB updated successfully with resolution: ${RESOLUTION} in gfxterm mode!"
    log_info "Backup preserved at: ${BACKUP_FILE}"
else
    log_error "GRUB update failed! Rolling back changes to preserve original configuration..."
    run_as_root cp "$BACKUP_FILE" "$GRUB_FILE"
    log_warn "Original configuration restored."
    exit 1
fi
