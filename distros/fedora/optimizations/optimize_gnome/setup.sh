#!/usr/bin/env bash
# ==============================================================================
# Fedora GNOME Setup Forwarder -> Canonical desktop/gnome/setup.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

if [[ -f "$REPO_DIR/desktop/gnome/setup.sh" ]]; then
    exec bash "$REPO_DIR/desktop/gnome/setup.sh" "$@"
else
    echo "[ERR] Canonical GNOME setup not found at $REPO_DIR/desktop/gnome/setup.sh" >&2
    exit 1
fi
