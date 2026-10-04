#!/usr/bin/env bash
# ==============================================================================
# Fedora KDE Setup Forwarder -> Canonical desktop/kde/setup.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

if [[ -f "$REPO_DIR/desktop/kde/setup.sh" ]]; then
    exec bash "$REPO_DIR/desktop/kde/setup.sh" "$@"
else
    echo "[ERR] Canonical KDE setup not found at $REPO_DIR/desktop/kde/setup.sh" >&2
    exit 1
fi
