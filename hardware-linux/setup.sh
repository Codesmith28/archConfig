#!/usr/bin/env bash
# ==============================================================================
# archConfig Linux Hardware Optimizations Master Runner
# ==============================================================================
# Distro-agnostic hardware optimizations for Linux hosts (Fedora, Arch, Ubuntu, OmArchy):
# 1. battery         : 85% charging cap & deep sleep (S3) threshold control
# 2. usb-wake        : USB sleep isolation (Hot backpack mouse/dongle wake block)
# 3. bluetooth-sleep : Clean A2DP audio disconnect before sleep & resync on resume
# 4. rog-nvidia      : ASUS ROG + NVIDIA RTX D3cold, Cardwire eBPF & debounced switching
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

# Guard: Ensure running on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    log_info "Hardware optimizations in 'hardware-linux' are only intended for Linux systems. Skipping on $(uname -s)."
    exit 0
fi

MODULES=("battery" "usb-wake" "bluetooth" "rog-nvidia")
REQUESTED=("$@")

should_run() {
    local mod="$1"
    if [[ ${#REQUESTED[@]} -eq 0 ]]; then
        return 0
    fi
    for r in "${REQUESTED[@]}"; do
        [[ "$r" == "$mod" || "$r" == "--verify" || "$r" == "-v" || "$r" == "verify" || "$r" == "status" ]] && return 0
    done
    return 1
}

IS_VERIFY=0
for arg in "${REQUESTED[@]}"; do
    if [[ "$arg" == "--verify" || "$arg" == "-v" || "$arg" == "verify" || "$arg" == "status" ]]; then
        IS_VERIFY=1
        break
    fi
done

echo -e "\n${BOLD}=== archConfig Linux Hardware Optimizations ===${NC}\n"

for mod in "${MODULES[@]}"; do
    mod_dir="$SCRIPT_DIR/$mod"
    if [[ -d "$mod_dir" ]] && should_run "$mod"; then
        if [[ -f "$mod_dir/setup.sh" ]]; then
            log_info "Processing module: ${BOLD}$mod${NC}"
            if [[ $IS_VERIFY -eq 1 ]]; then
                bash "$mod_dir/setup.sh" --verify || true
            else
                bash "$mod_dir/setup.sh" "${REQUESTED[@]}"
            fi
            echo ""
        fi
    fi
done

log_success "Linux hardware optimization sequence finished."
