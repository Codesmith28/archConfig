#!/bin/bash
# Generic progress notification helper
# Usage: notify-progress.sh <title> <notification_id> <percentage>

TITLE="$1"
NOTIF_ID="$2"
PERCENTAGE="$3"

# Clamp percentage between 0 and 100
PERCENTAGE=$((PERCENTAGE < 0 ? 0 : PERCENTAGE > 100 ? 100 : PERCENTAGE))

# Send notification with progress bar hint
notify-send \
  -h "int:value:$PERCENTAGE" \
  -h "string:x-canonical-private-synchronous:$NOTIF_ID" \
  -t 1000 \
  -r "$NOTIF_ID" \
  "$TITLE" \
  "$PERCENTAGE%"
