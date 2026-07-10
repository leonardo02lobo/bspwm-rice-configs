#!/bin/bash
STAMP_FILE="/tmp/.eww_volume_stamp"
STAMP=$(date +%s%N)
echo "$STAMP" > "$STAMP_FILE"

eww open volume

(
  MY_STAMP="$STAMP"
  sleep 3
  if [[ "$(cat "$STAMP_FILE" 2>/dev/null)" == "$MY_STAMP" ]]; then
    eww close volume
  fi
) &
