#!/usr/bin/env bash
# ==============================================================================
# omArchy Optimizations - Setup Script
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library functions
source "$SCRIPT_DIR/lib/common.sh"

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

    if [[ -f "$dir/install.sh" ]]; then
        log_info "Executing custom installer for module: ${BOLD}$dir_name${NC}"
        bash "$dir/install.sh" "$BIN_DEST" "$SERVICE_DEST"
    else
        install_optimization "$dir" "$BIN_DEST" "$SERVICE_DEST"
    fi
done

log_success "Optimization setup completed successfully!"
