#!/usr/bin/env bash
# ==============================================================================
# Ubuntu GRUB Configuration & Resolution Setup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../optimizations/lib"

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

RESOLUTION="${1:-1920x1200,auto}"
GRUB_FILE="/etc/default/grub"

if [[ ! -f "$GRUB_FILE" ]]; then
    log_error "GRUB configuration file not found at $GRUB_FILE"
    exit 1
fi

log_info "Configuring GRUB resolution to: ${RESOLUTION}..."

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${GRUB_FILE}.bak.${TIMESTAMP}"

log_info "Creating backup at ${BACKUP_FILE}..."
run_as_root cp "$GRUB_FILE" "$BACKUP_FILE"

# Update or insert GRUB_GFXMODE
if grep -q "^[#]*GRUB_GFXMODE=" "$GRUB_FILE"; then
    run_as_root sed -i "s|^[#]*GRUB_GFXMODE=.*|GRUB_GFXMODE=\"${RESOLUTION}\"|" "$GRUB_FILE"
else
    echo "GRUB_GFXMODE=\"${RESOLUTION}\"" | run_as_root tee -a "$GRUB_FILE" >/dev/null
fi

# Update or insert GRUB_GFXPAYLOAD_LINUX
if grep -q "^[#]*GRUB_GFXPAYLOAD_LINUX=" "$GRUB_FILE"; then
    run_as_root sed -i 's|^[#]*GRUB_GFXPAYLOAD_LINUX=.*|GRUB_GFXPAYLOAD_LINUX="keep"|' "$GRUB_FILE"
else
    echo 'GRUB_GFXPAYLOAD_LINUX="keep"' | run_as_root tee -a "$GRUB_FILE" >/dev/null
fi

echo ""
log_info "Changes applied to ${GRUB_FILE}:"
diff -u "$BACKUP_FILE" "$GRUB_FILE" || true
echo ""

log_info "Running update-grub..."
if run_as_root update-grub; then
    log_success "GRUB updated successfully with resolution: ${RESOLUTION}!"
    log_info "Backup preserved at: ${BACKUP_FILE}"
else
    log_error "update-grub failed! Rolling back changes..."
    run_as_root cp "$BACKUP_FILE" "$GRUB_FILE"
    log_warn "Original configuration restored."
    exit 1
fi
