#!/usr/bin/env bash
# ==============================================================================
# ACPI GPE, Interrupt & PCIe AER Storm Guard
# - Boot & S3-resume persistence for masked storming ACPI GPEs
# - Rate-aware GPE interrupt storm detection (avoids masking healthy cumulative GPEs)
# - Diagnostics (--verify / --status) for ACPI GPEs, /proc/interrupts, and PCIe AER
# ==============================================================================
set -euo pipefail

BASELINE_FILE="/run/acpi-gpe-baseline"
MASKED_FILE="/run/acpi-masked-gpes"

if [[ ! -w /run ]]; then
    BASELINE_FILE="/tmp/acpi-gpe-baseline"
    MASKED_FILE="/tmp/acpi-masked-gpes"
fi

record_baseline() {
    : > "$BASELINE_FILE" 2>/dev/null || return 0
    local gpe_file gpe_name count
    for gpe_file in /sys/firmware/acpi/interrupts/gpe*; do
        [[ -f "$gpe_file" ]] || continue
        gpe_name="$(basename "$gpe_file")"
        [[ "$gpe_name" == "gpe_all" ]] && continue
        count="$(awk '{print $1}' "$gpe_file" 2>/dev/null || echo 0)"
        [[ "$count" =~ ^[0-9]+$ ]] || continue
        printf '%s %s\n' "$gpe_name" "$count" >> "$BASELINE_FILE" 2>/dev/null || true
    done
}

# Re-apply GPE masks recorded earlier in this boot (ACPI hardware clears masks on S3 resume)
reapply_masked_gpes() {
    [[ -f "$MASKED_FILE" ]] || return 0
    local gpe_name gpe_file status
    while read -r gpe_name; do
        [[ -n "$gpe_name" ]] || continue
        gpe_file="/sys/firmware/acpi/interrupts/$gpe_name"
        [[ -f "$gpe_file" && -w "$gpe_file" ]] || continue
        status="$(awk '{print $2}' "$gpe_file" 2>/dev/null || echo "")"
        if [[ "$status" == "EN" ]]; then
            echo "disable" > "$gpe_file" 2>/dev/null || true
            logger -t acpi-storm-guard "[INFO] Re-masked previously storming ACPI $gpe_name after resume" 2>/dev/null || true
        fi
    done < "$MASKED_FILE"
}

# Sample active EN GPEs over 1s and mask only actively storming vectors:
#   - High rate: delta >= 500 interrupts/sec
#   - Runaway cumulative + still firing: count > 50000 and delta > 50 interrupts/sec
enforce_gpe_rate_guard() {
    local -A pre_counts=()
    local gpe_file gpe_name count status

    for gpe_file in /sys/firmware/acpi/interrupts/gpe*; do
        [[ -f "$gpe_file" ]] || continue
        gpe_name="$(basename "$gpe_file")"
        [[ "$gpe_name" == "gpe_all" ]] && continue
        status="$(awk '{print $2}' "$gpe_file" 2>/dev/null || echo "")"
        [[ "$status" == "EN" ]] || continue
        count="$(awk '{print $1}' "$gpe_file" 2>/dev/null || echo 0)"
        [[ "$count" =~ ^[0-9]+$ ]] && pre_counts["$gpe_name"]="$count"
    done

    if [[ ${#pre_counts[@]} -eq 0 ]]; then
        return 0
    fi

    sleep 1

    for gpe_name in "${!pre_counts[@]}"; do
        gpe_file="/sys/firmware/acpi/interrupts/$gpe_name"
        [[ -f "$gpe_file" && -w "$gpe_file" ]] || continue
        count="$(awk '{print $1}' "$gpe_file" 2>/dev/null || echo 0)"
        status="$(awk '{print $2}' "$gpe_file" 2>/dev/null || echo "")"
        [[ "$count" =~ ^[0-9]+$ && "$status" == "EN" ]] || continue

        local delta=$(( count - pre_counts["$gpe_name"] ))
        if [[ "$delta" -ge 500 ]] || { [[ "$count" -gt 50000 ]] && [[ "$delta" -gt 50 ]]; }; then
            echo "disable" > "$gpe_file" 2>/dev/null || true
            if ! grep -qxF "$gpe_name" "$MASKED_FILE" 2>/dev/null; then
                echo "$gpe_name" >> "$MASKED_FILE" 2>/dev/null || true
            fi
            logger -t acpi-storm-guard "[WARN] Masked storming ACPI $gpe_name (count=$count, rate=${delta}/s)" 2>/dev/null || true
        fi
    done
}

print_status() {
    echo "=== ACPI & PCIe Storm Diagnostics ==="
    if [[ -r /proc/cmdline ]]; then
        echo "Kernel cmdline: $(cat /proc/cmdline)"
        if grep -qw "pci=noaer" /proc/cmdline 2>/dev/null; then
            echo "PCIe AER suppression (pci=noaer): ACTIVE"
        else
            echo "PCIe AER suppression (pci=noaer): NOT active"
        fi
    fi

    echo ""
    echo "Active / Non-zero ACPI Interrupts:"
    if [[ -d /sys/firmware/acpi/interrupts ]]; then
        grep -H . /sys/firmware/acpi/interrupts/gpe_all /sys/firmware/acpi/interrupts/sci /sys/firmware/acpi/interrupts/gpe[0-9A-Fa-f]* 2>/dev/null | \
            grep -vE ': *0 +(invalid|disabled)' || echo "  None active"
    else
        echo "  /sys/firmware/acpi/interrupts unavailable in current namespace"
    fi

    echo ""
    echo "Key /proc/interrupts Counters (ACPI / GPIO / I2C / PCIe AER):"
    grep -E "^\s*(9|14|27|126|145):" /proc/interrupts 2>/dev/null || true

    echo ""
    echo "PCIe AER Hardware Error Counters:"
    local aer_found=0
    for f in /sys/bus/pci/devices/*/aer_dev_nonfatal /sys/bus/pci/devices/*/aer_rootport_total_err_cor; do
        [[ -r "$f" ]] || continue
        aer_found=1
        if [[ "$(basename "$f")" == "aer_dev_nonfatal" ]]; then
            local total
            total="$(awk '/^TOTAL_ERR_NONFATAL/{print $2}' "$f" 2>/dev/null || echo 0)"
            if [[ "${total:-0}" -gt 0 ]]; then
                echo "  $(basename "$(dirname "$f")") nonfatal AER errors: $total"
            fi
        else
            local cor
            cor="$(cat "$f" 2>/dev/null || echo 0)"
            if [[ "${cor:-0}" -gt 0 ]]; then
                echo "  $(basename "$(dirname "$f")") rootport correctable AER errors: $cor"
            fi
        fi
    done
    [[ $aer_found -eq 0 ]] && echo "  No AER sysfs nodes exposed (or pci=noaer active)"

    if [[ -f "$MASKED_FILE" ]] && [[ -s "$MASKED_FILE" ]]; then
        echo ""
        echo "Masked Storming GPEs ($MASKED_FILE):"
        cat "$MASKED_FILE"
    fi
}

case "${1:---enforce}" in
    --boot)
        record_baseline
        enforce_gpe_rate_guard
        ;;
    --resume)
        reapply_masked_gpes
        enforce_gpe_rate_guard
        if [[ -x /usr/local/bin/power-profile-switch.sh ]]; then
            /usr/local/bin/power-profile-switch.sh --force --now >/dev/null 2>&1 || true
        fi
        ;;
    --enforce|--check)
        enforce_gpe_rate_guard
        ;;
    --verify|--status|-s)
        print_status
        ;;
    *)
        echo "Usage: $0 [--boot|--resume|--enforce|--verify]" >&2
        exit 1
        ;;
esac

exit 0
