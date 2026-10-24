#!/usr/bin/env bash
# ==============================================================================
# Battery Charging Limit Sleep & Resume Hook
# Re-enforces battery charge threshold after waking from suspend / hibernate
# ==============================================================================
case "${1:-}" in
    post)
        if [[ -x /usr/local/bin/set-battery-limit.sh ]]; then
            /usr/local/bin/set-battery-limit.sh >/dev/null 2>&1 || true
        fi
        ;;
esac
