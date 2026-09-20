#!/usr/bin/env bash
# ==============================================================================
# Ubuntu Machine Setup & Synchronization Master Script
# ==============================================================================
# Delegates to the unified, robust setup.sh master script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/setup.sh" "$@"
