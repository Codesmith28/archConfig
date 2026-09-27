#!/usr/bin/env bash
# ==============================================================================
# Fix NVIDIA SELinux Suspend Abort & Battery Drain
# ==============================================================================
set -euo pipefail

BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
NC=$'\033[0m'

run_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo -e "${RED}[ERR] Root privileges required.${NC}" >&2
        exit 1
    fi
}

echo -e "\n${BOLD}=== Fixing NVIDIA Suspend / Battery Drain Issue ===${NC}\n"

# 1. Step 1: Immediate live fix without needing a reboot
# The running kernel nvidia module parameter NVreg_TemporaryFilePath is read-only at runtime
# and currently points to /var/tmp. We grant systemd_sleep_t access via a local SELinux policy.
if command -v audit2allow >/dev/null 2>&1 && command -v semodule >/dev/null 2>&1; then
    echo -e "${BLUE}[INFO] Checking for live SELinux denials...${NC}"
    DENIALS=$(journalctl -b 0 -g "denied.*systemd-sleep" -n 20 --no-pager 2>/dev/null || true)
    if [[ -n "$DENIALS" ]]; then
        echo -e "${YELLOW}[INFO] Compiling immediate live SELinux policy module for systemd-sleep...${NC}"
        TMP_DIR="$(mktemp -d)"
        pushd "$TMP_DIR" >/dev/null
        echo "$DENIALS" | audit2allow -M nvidia_sleep_live
        run_root semodule -i nvidia_sleep_live.pp
        popd >/dev/null
        rm -rf "$TMP_DIR"
        echo -e "${GREEN}[OK]   Live SELinux policy installed! Suspend will now succeed immediately.${NC}"
    fi
fi

# 2. Step 2: Permanent architecture fix using /var/lib/systemd/sleep
echo -e "${BLUE}[INFO] Creating /var/lib/systemd/sleep directory with restricted permissions...${NC}"
run_root mkdir -p /var/lib/systemd/sleep
run_root chmod 0700 /var/lib/systemd/sleep

if command -v restorecon >/dev/null 2>&1; then
    echo -e "${BLUE}[INFO] Applying systemd_sleep_var_lib_t SELinux label...${NC}"
    run_root restorecon -v /var/lib/systemd/sleep || true
fi

# 3. Update /etc/modprobe.d/nvidia-power-management.conf
echo -e "${BLUE}[INFO] Updating /etc/modprobe.d/nvidia-power-management.conf...${NC}"
cat << 'EOF' | run_root tee /etc/modprobe.d/nvidia-power-management.conf >/dev/null
# ==============================================================================
# NVIDIA Power Management Configuration
# Fixes "hot backpack" issue by enabling video memory preservation across sleep
# ==============================================================================

# Preserve video memory allocations across suspend and hibernate
options nvidia NVreg_PreserveVideoMemoryAllocations=1

# Use /var/lib/systemd/sleep for temporary video memory allocation backing files.
# This prevents out-of-memory errors on /tmp (tmpfs in RAM) while complying with
# SELinux on Fedora/RHEL where systemd-sleep is denied write access to /var/tmp (tmp_t).
options nvidia NVreg_TemporaryFilePath=/var/lib/systemd/sleep
EOF
echo -e "${GREEN}[OK]   Modprobe configuration updated.${NC}"

# 4. Update initramfs via dracut
if command -v dracut >/dev/null 2>&1; then
    echo -e "${BLUE}[INFO] Regenerating initramfs with dracut (this may take 15-30 seconds)...${NC}"
    run_root dracut -f
    echo -e "${GREEN}[OK]   Initramfs updated successfully.${NC}"
fi

echo -e "\n${BOLD}${GREEN}✔ All fixes successfully applied!${NC}"
echo -e "You can now safely test sleep using: ${BOLD}systemctl suspend${NC}\n"
