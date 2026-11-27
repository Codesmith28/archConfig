#!/usr/bin/env bash
# ==============================================================================
# ACPI Storm Guard Sleep & Resume Hook
# Re-applies masked GPEs cleared across S3 deep sleep and reconciles power state
# ==============================================================================
case "${1:-}" in
    post)
        if [[ -x /usr/local/bin/acpi-storm-guard.sh ]]; then
            /usr/local/bin/acpi-storm-guard.sh --resume >/dev/null 2>&1 || true
        fi
        ;;
esac
