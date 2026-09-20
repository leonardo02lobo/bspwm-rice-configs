#!/usr/bin/env bash
# One JSON snapshot of Spotify's MPRIS state per invocation, so the eww widget
# needs a single defpoll instead of one process per field.
#
# Always exits 0 with parseable JSON: a defpoll whose script fails keeps its
# previous value, which would leave the panel showing a track from a session
# that is already closed.

readonly PLAYER="spotify"
readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pl() { playerctl -p "$PLAYER" "$@" 2>/dev/null; }

num() { [[ "$1" =~ ^[0-9]+$ ]] && echo "$1" || echo 0; }
fmt() { printf '%d:%02d' $(( $1 / 60 )) $(( $1 % 60 )); }

status="$(pl status)"
[[ -z "$status" ]] && status="Offline"

title=""
artist=""
shuffle="Off"
repeat="None"
pos_secs=0
len_secs=0
art=""

if [[ "$status" != "Offline" ]]; then
  title="$(pl metadata title)"
  artist="$(pl metadata artist)"
  shuffle="$(pl shuffle)"
  repeat="$(pl loop)"

  pos="$(pl position)"
  pos_secs="$(num "${pos%%.*}")"

  len_us="$(pl metadata mpris:length)"
  len_secs=$(( $(num "${len_us%%.*}") / 1000000 ))

  # One call for both fields; the helper returns immediately, downloading in
  # the background on a miss, so this stays off the network path.
  ids="$(pl metadata --format '{{mpris:trackid}}|{{mpris:artUrl}}')"
  art="$("$HERE/get_album_art.sh" "${ids%%|*}" "${ids#*|}")"
fi

len_fmt="$(fmt "$len_secs")"
# A scale with min 0 and max 0 is degenerate; 1 keeps the bar empty instead.
(( len_secs > 0 )) || len_secs=1

jq -cn \
  --arg  status   "$status" \
  --arg  title    "$title" \
  --arg  artist   "$artist" \
  --arg  shuffle  "${shuffle:-Off}" \
  --arg  repeat   "${repeat:-None}" \
  --arg  art      "$art" \
  --argjson position "$pos_secs" \
  --argjson length   "$len_secs" \
  --arg  position_fmt "$(fmt "$pos_secs")" \
  --arg  length_fmt   "$len_fmt" \
  '{$status, $title, $artist, $shuffle, $repeat, $art, $position, $length, $position_fmt, $length_fmt}'
