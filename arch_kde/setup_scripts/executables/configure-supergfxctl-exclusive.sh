#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") [gpu-mode]"
    echo "       $(basename "$0") --gpu-mode <gpu-mode>"
    echo "Default gpu-mode: Hybrid"
    echo "Accepted modes (case-insensitive): Integrated, Hybrid, Vfio, AsusEgpu, AsusMuxDgpu"
}

log() {
    echo "$*"
}

warn() {
    echo "WARN: $*" >&2
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

run_as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        die "This script requires root privileges. Run as root or install sudo."
    fi
}

require_command() {
    local command_name="$1"
    command -v "$command_name" >/dev/null 2>&1 || die "Required command '$command_name' is not installed."
}

normalize_mode() {
    local raw_input="${1:-Hybrid}"
    local compact_input

    compact_input="$(printf '%s' "$raw_input" | tr '[:upper:]' '[:lower:]' | tr -d ' _-')"

    case "$compact_input" in
    integrated|intel|igpu)
        echo "Integrated"
        ;;
    hybrid|auto)
        echo "Hybrid"
        ;;
    vfio)
        echo "Vfio"
        ;;
    asusegpu|egpu|externalgpu|external)
        echo "AsusEgpu"
        ;;
    asusmuxdgpu|muxdgpu|ultimate|dedicated|discrete|dgpu|nvidia)
        echo "AsusMuxDgpu"
        ;;
    *)
        die "Unsupported GPU mode '$raw_input'. Use Integrated, Hybrid, Vfio, AsusEgpu, or AsusMuxDgpu."
        ;;
    esac
}

normalize_reported_mode() {
    local reported_mode="${1:-}"
    local lowered_mode

    lowered_mode="$(printf '%s' "$reported_mode" | tr '[:upper:]' '[:lower:]')"

    case "$lowered_mode" in
    *integrated*)
        echo "Integrated"
        ;;
    *hybrid*)
        echo "Hybrid"
        ;;
    *vfio*)
        echo "Vfio"
        ;;
    *asusegpu*|*egpu*)
        echo "AsusEgpu"
        ;;
    *asusmuxdgpu*|*ultimate*|*dgpu*|*discrete*|*dedicated*)
        echo "AsusMuxDgpu"
        ;;
    *)
        printf '%s' "$reported_mode"
        ;;
    esac
}

service_exists() {
    local service_name="$1"

    if systemctl list-unit-files --type=service --all --no-legend 2>/dev/null | awk '{print $1}' | grep -Fxq "$service_name"; then
        return 0
    fi

    systemctl list-units --type=service --all --no-legend 2>/dev/null | awk '{print $1}' | grep -Fxq "$service_name"
}

ensure_service_enabled() {
    local service_name="$1"
    if ! service_exists "$service_name"; then
        die "Required service '$service_name' is not available on this system."
    fi
    log "Ensuring $service_name is enabled and running..."
    run_as_root systemctl enable --now "$service_name" >/dev/null
    changed_services+=("enabled+started:$service_name")
}

disable_conflicting_service() {
    local service_name="$1"

    if service_exists "$service_name"; then
        log "Disabling conflicting service: $service_name"
        local service_changed=false

        if systemctl is-active --quiet "$service_name"; then
            run_as_root systemctl stop "$service_name" >/dev/null
            service_changed=true
        fi

        if systemctl is-enabled --quiet "$service_name" >/dev/null 2>&1; then
            run_as_root systemctl disable "$service_name" >/dev/null
            service_changed=true
        fi

        if [[ "$service_changed" == true ]]; then
            changed_services+=("stopped+disabled:$service_name")
        else
            changed_services+=("already-disabled:$service_name")
        fi
    else
        skipped_services+=("$service_name")
    fi
}

join_by_comma() {
    local IFS=", "
    echo "$*"
}

gpu_mode_input="Hybrid"
positional_mode_set=false

while [[ $# -gt 0 ]]; do
    case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
    --gpu-mode)
        shift
        [[ $# -gt 0 ]] || die "--gpu-mode requires a value."
        gpu_mode_input="$1"
        ;;
    --gpu-mode=*)
        gpu_mode_input="${1#*=}"
        ;;
    -*)
        usage
        die "Unknown option: $1"
        ;;
    *)
        if [[ "$positional_mode_set" == true ]]; then
            usage
            die "Too many arguments."
        fi
        gpu_mode_input="$1"
        positional_mode_set=true
        ;;
    esac
    shift
done

declare -a changed_services=()
declare -a skipped_services=()

require_command "systemctl"
require_command "supergfxctl"

if command -v powerprofilesctl >/dev/null 2>&1; then
    log "powerprofilesctl found."
else
    warn "Optional command 'powerprofilesctl' is not installed."
fi

target_mode="$(normalize_mode "$gpu_mode_input")"

current_mode_raw="$(supergfxctl -g 2>/dev/null || true)"
current_mode="$(normalize_reported_mode "$current_mode_raw")"

if [[ -n "$current_mode" ]]; then
    log "Current supergfxctl mode: $current_mode"
fi

ensure_service_enabled "asusd.service"
ensure_service_enabled "supergfxd.service"

disable_conflicting_service "optimus-manager.service"
disable_conflicting_service "bumblebeed.service"
disable_conflicting_service "nvidia-persistence-mode.service"
disable_conflicting_service "nvidia-persistenced.service"

log "Masking nvidia-persistence-mode.service to prevent conflicts with supergfxctl."
run_as_root systemctl mask "nvidia-persistence-mode.service" >/dev/null
changed_services+=("masked:nvidia-persistence-mode.service")

log "Setting GPU mode with supergfxctl: $target_mode"
if ! set_mode_output="$(supergfxctl -m "$target_mode" 2>&1)"; then
    die "Failed to set mode '$target_mode'. supergfxctl output: $set_mode_output"
fi

if [[ -n "$set_mode_output" ]]; then
    log "$set_mode_output"
fi

reported_mode_raw="$(supergfxctl -g 2>/dev/null || true)"
reported_mode="$(normalize_reported_mode "$reported_mode_raw")"

requires_reboot_or_logout="yes"
if [[ "$current_mode" == "$target_mode" ]]; then
    requires_reboot_or_logout="likely no (target mode already active)"
fi

if [[ "${set_mode_output,,}" =~ reboot|restart|logout|log[[:space:]]out|re-login|relogin ]]; then
    requires_reboot_or_logout="yes"
fi

nvidia_smi_summary="not run"

if [[ "$target_mode" == "Integrated" || "$reported_mode" == "Integrated" ]]; then
    nvidia_smi_summary="skipped (Integrated mode: no NVIDIA device in nvidia-smi is expected)"
    log "Integrated mode detected: 'nvidia-smi' showing no NVIDIA device is expected."
elif command -v nvidia-smi >/dev/null 2>&1; then
    if nvidia_smi_output="$(nvidia-smi 2>&1)"; then
        nvidia_smi_summary="success"
        log "nvidia-smi succeeded and detected NVIDIA device(s)."
    else
        nvidia_smi_summary="failed"
        warn "nvidia-smi failed in a non-Integrated mode."
        warn "If btop shows GPU activity but nvidia-smi shows no device, reboot or log out/in, then re-check with: supergfxctl -g && nvidia-smi"
        warn "nvidia-smi output: $nvidia_smi_output"
    fi
else
    nvidia_smi_summary="unavailable (nvidia-smi not installed)"
    warn "Optional command 'nvidia-smi' is not installed; cannot validate NVIDIA visibility."
fi

echo
log "Summary:"
if [[ ${#changed_services[@]} -gt 0 ]]; then
    log "  Services changed: $(join_by_comma "${changed_services[@]}")"
else
    log "  Services changed: none"
fi

if [[ ${#skipped_services[@]} -gt 0 ]]; then
    log "  Services not present: $(join_by_comma "${skipped_services[@]}")"
fi

log "  GPU mode target: $target_mode"
if [[ -n "$reported_mode" ]]; then
    log "  GPU mode reported now: $reported_mode"
fi
log "  nvidia-smi check: $nvidia_smi_summary"
log "  Reboot/logout likely required: $requires_reboot_or_logout"
