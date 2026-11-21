#!/usr/bin/env bash
# ==============================================================================
# NVIDIA GPU Detector for Hyprland
# ==============================================================================
# Checks strictly for the presence of an active NVIDIA discrete GPU.
# Applies NVIDIA-specific Wayland variables only when NVIDIA hardware is present.
# Otherwise, defaults to standard Mesa/Wayland graphics without overrides.
# ==============================================================================
set -euo pipefail

IS_NVIDIA=false
NVIDIA_CARD=""

# 1. Check sysfs DRM vendor IDs (0x10de = NVIDIA)
for vendor_file in /sys/class/drm/card[0-9]/device/vendor; do
    if [ -f "$vendor_file" ] && [ "$(cat "$vendor_file" 2>/dev/null || true)" = "0x10de" ]; then
        IS_NVIDIA=true
        card_dir=$(dirname "$(dirname "$vendor_file")")
        NVIDIA_CARD="/dev/dri/$(basename "$card_dir")"
        break
    fi
done

# 2. Fallback check via lspci or loaded kernel modules
if [ "$IS_NVIDIA" = false ]; then
    if command -v lspci >/dev/null 2>&1; then
        if lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' | grep -qi '10de:\|NVIDIA'; then
            IS_NVIDIA=true
        fi
    fi
    if [ "$IS_NVIDIA" = false ] && lsmod 2>/dev/null | grep -qEi 'nvidia_drm|nvidia_modeset|nvidia'; then
        IS_NVIDIA=true
    fi
fi

# ------------------------------------------------------------------------------
# Output Environment Variables
# ------------------------------------------------------------------------------
get_env_vars() {
    local env_vars=()

    # Universal Wayland & Browser Optimizations (prevents sluggish horizontal scrolling in Zen/Firefox)
    env_vars+=("MOZ_ENABLE_WAYLAND=1")
    env_vars+=("MOZ_WEBRENDER=1")
    env_vars+=("widget.wayland.smooth-scroll=1")

    if [ "$IS_NVIDIA" = true ]; then
        # Proprietary NVIDIA Wayland compatibility layer
        env_vars+=("LIBVA_DRIVER_NAME=nvidia")
        env_vars+=("GBM_BACKEND=nvidia-drm")
        env_vars+=("__GLX_VENDOR_LIBRARY_NAME=nvidia")
        env_vars+=("NVD_BACKEND=direct")
        env_vars+=("ELECTRON_OZONE_PLATFORM_HINT=auto")
        if [ -n "$NVIDIA_CARD" ] && [ -e "$NVIDIA_CARD" ]; then
            env_vars+=("AQ_DRM_DEVICES=$NVIDIA_CARD")
        fi
    fi

    printf '%s\n' "${env_vars[@]}"
}

ACTION="${1:---summary}"

case "$ACTION" in
    --is-nvidia)
        if [ "$IS_NVIDIA" = true ]; then echo "true"; else echo "false"; fi
        ;;
    --env)
        get_env_vars | while IFS= read -r line; do
            echo "export $line"
        done
        ;;
    --hypr)
        get_env_vars | while IFS= read -r line; do
            key="${line%%=*}"
            val="${line#*=}"
            echo "env = $key,$val"
        done
        ;;
    --apply)
        while IFS='=' read -r key val; do
            export "$key=$val"
            if command -v systemctl >/dev/null 2>&1; then
                systemctl --user set-environment "$key=$val" 2>/dev/null || true
            fi
            if command -v dbus-update-activation-environment >/dev/null 2>&1; then
                dbus-update-activation-environment --systemd "$key" 2>/dev/null || true
            fi
        done < <(get_env_vars)
        ;;
    --summary|*)
        echo "NVIDIA Hardware Present : $IS_NVIDIA"
        if [ "$IS_NVIDIA" = true ]; then
            echo "NVIDIA DRM Device       : ${NVIDIA_CARD:-auto}"
        fi
        echo "Active Environment Variables:"
        get_env_vars | sed 's/^/  /'
        ;;
esac
