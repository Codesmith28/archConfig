#!/usr/bin/env bash
# ==============================================================================
# macOS Git & SSH Setup
# ==============================================================================
# Delegates to the unified cross-distro setup in core/scripts/setup_git.sh
# ==============================================================================
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exec bash "$REPO_DIR/core/scripts/setup_git.sh" "$@"
