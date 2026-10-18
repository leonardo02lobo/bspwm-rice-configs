#!/bin/bash
# Toda llamada a eww pasa por eww_call.sh: arranca el daemon si no está, le
# pone un timeout e impide que un `open` fallido se convierta en otro daemon.
EWW=("$HOME/.config/bspwm/scripts/lib/eww_call.sh")

STAMP_FILE="/tmp/.eww_brightness_stamp"
STAMP=$(date +%s%N)
echo "$STAMP" > "$STAMP_FILE"

"${EWW[@]}" open brightness

(
  MY_STAMP="$STAMP"
  sleep 3
  if [[ "$(cat "$STAMP_FILE" 2>/dev/null)" == "$MY_STAMP" ]]; then
    "${EWW[@]}" close brightness
  fi
) &
