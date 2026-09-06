#!/usr/bin/env bash
# ==============================================================================
# omArchy Optimizations - Setup Script
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library functions
if [[ -f "$SCRIPT_DIR/lib/commons.sh" ]]; then
    source "$SCRIPT_DIR/lib/commons.sh"
else
    source "$SCRIPT_DIR/lib/common.sh"
fi

BIN_DEST="${BIN_DEST:-/usr/local/bin}"
SERVICE_DEST="${SERVICE_DEST:-/etc/systemd/system}"

log_info "Starting omArchy system optimizations setup..."
run_as_root mkdir -p "$BIN_DEST" "$SERVICE_DEST"

for dir in "$SCRIPT_DIR"/*/; do
    [ -d "$dir" ] || continue
    dir_name="$(basename "$dir")"

    # Skip library and hidden directories
    [[ "$dir_name" == "lib" || "$dir_name" =~ ^\. ]] && continue

    log_info "Checking module: ${BOLD}$dir_name${NC}"

    if ! validate_optimization_dir "$dir"; then
        log_warn "Validation failed for module: $dir_name (skipping)"
        continue
    fi

    install_optimization "$dir" "$BIN_DEST" "$SERVICE_DEST"
done

log_success "Optimization setup completed successfully!"
