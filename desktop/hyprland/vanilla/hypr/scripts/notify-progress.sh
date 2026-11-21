#!/usr/bin/env bash
# ==============================================================================
# Universal OSD Progress & Status Notification Helper
# Provides modern notification cards with native DBus progress hints (-h int:value)
# and clean monospace Unicode/ASCII progress bar fallback formatting.
# ==============================================================================
set -euo pipefail

IS_CLI=false
if [[ "${1:-}" == "--cli" || "${1:-}" == "-c" ]]; then
    IS_CLI=true
    shift
fi

TITLE="${1:-Progress}"
TAG_OR_ID="${2:-osd}"
PERCENTAGE="${3:-}"
SUBTEXT="${4:-}"
ICON="${5:-}"

# Map well-known tags to stable integer replacement IDs and canonical tags
case "$TAG_OR_ID" in
    brightness)     NOTIF_ID=999; CANONICAL_TAG="brightness" ;;
    volume)         NOTIF_ID=998; CANONICAL_TAG="volume" ;;
    mic|microphone) NOTIF_ID=997; CANONICAL_TAG="mic" ;;
    wifi|network)   NOTIF_ID=996; CANONICAL_TAG="wifi" ;;
    bluetooth|bt)   NOTIF_ID=995; CANONICAL_TAG="bluetooth" ;;
    screenshot)     NOTIF_ID=994; CANONICAL_TAG="screenshot" ;;
    [0-9]*)
        NOTIF_ID="$TAG_OR_ID"
        CANONICAL_TAG="osd-$TAG_OR_ID"
        ;;
    *)
        NOTIF_ID=990
        CANONICAL_TAG="$TAG_OR_ID"
        ;;
esac

# Function to render monospace Unicode progress bar
render_bar() {
    local pct="${1:-0}"
    local width="${2:-15}"
    if (( pct < 0 )); then pct=0; fi
    if (( pct > 100 )); then pct=100; fi
    local filled=$(( (pct * width + 50) / 100 ))
    if (( filled > width )); then filled=$width; fi
    local empty=$(( width - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done
    printf "[%s] %3d%%" "$bar" "$pct"
}

# Process percentage if provided
HINT_ARGS=()
HAS_BAR=false
PCT_NUM=""
if [[ -n "$PERCENTAGE" ]]; then
    CLEAN_PCT="${PERCENTAGE//[^0-9]/}"
    if [[ -n "$CLEAN_PCT" ]]; then
        PCT_NUM=$(( CLEAN_PCT < 0 ? 0 : CLEAN_PCT > 100 ? 100 : CLEAN_PCT ))
        HINT_ARGS+=(-h "int:value:$PCT_NUM")
        BAR_STR="$(render_bar "$PCT_NUM" 15)"
        HAS_BAR=true
    fi
fi

# Build clean monospace body text
BODY=""
if [[ -n "$SUBTEXT" ]]; then
    BODY="$SUBTEXT"
fi

if [[ "$HAS_BAR" == "true" ]]; then
    if [[ -n "$BODY" ]]; then
        BODY="${BODY}"$'\n'"${BAR_STR}"
    else
        BODY="${BAR_STR}"
    fi
fi

# Fallback for empty body
if [[ -z "$BODY" ]]; then
    BODY="${PERCENTAGE:-OK}"
fi

# Icon argument if provided or resolved
ICON_ARGS=()
if [[ -n "$ICON" ]]; then
    ICON_ARGS+=(-i "$ICON")
fi

# CLI fallback: if explicitly requested or running without display
if [[ "$IS_CLI" == "true" ]] || [[ "${NOTIFY_CLI:-0}" == "1" ]] || { [[ -t 1 ]] && [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; }; then
    printf "%s: %s\n" "$TITLE" "$BODY"
    exit 0
fi

# If notify-send is missing, print to stdout if tty, then exit 0 safely
if ! command -v notify-send >/dev/null 2>&1; then
    if [[ -t 1 ]]; then
        printf "%s: %s\n" "$TITLE" "$BODY"
    fi
    exit 0
fi

# Dispatch notification with synchronous tags and progress hints
notify-send \
    -a "OSD" \
    -r "$NOTIF_ID" \
    -h "string:x-canonical-private-synchronous:$CANONICAL_TAG" \
    -h "string:synchronous:$CANONICAL_TAG" \
    -t 1200 \
    "${HINT_ARGS[@]}" \
    "${ICON_ARGS[@]}" \
    "$TITLE" \
    "$BODY" 2>/dev/null || true
