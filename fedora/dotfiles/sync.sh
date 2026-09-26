#!/usr/bin/env bash
# Backward-compatibility wrapper delegating to root sync.sh
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$REPO_DIR/sync.sh" --distro fedora --de gnome "$@"
