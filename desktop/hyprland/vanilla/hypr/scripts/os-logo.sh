#!/usr/bin/env bash
# ==============================================================================
# OS Logo Glyph Resolver for Waybar
# Rules: Fedora ->  | Else (all other systems) -> 󰣇
# ==============================================================================
set -euo pipefail

if [[ -f /etc/os-release ]] && grep -qi "fedora" /etc/os-release; then
    echo ""
else
    echo "󰣇"
fi
