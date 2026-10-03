#!/bin/bash
# Applies the hover state of the Spotify trigger in the bar.
#
#   hover_player.sh show   reveal the panel
#   hover_player.sh hide   collapse it after a grace delay, then close it
#
# `show` is a no-op when the panel is already up, and that is load-bearing:
# `eww open` on an open window destroys and recreates it, which fires a fresh
# enter event under a stationary pointer and calls this script again. Without
# the guard it looped about eighteen times a second while the pointer simply
# rested on the panel.
#
# The window is closed after collapsing rather than left open with the revealer
# shut, because eww does not shrink the toplevel back down: an open-but-
# collapsed panel leaves a 365x176 window with no input shape over the desktop,
# swallowing every click underneath.
#
# Whether a hide is a false alarm is settled by asking X where the pointer
# actually is, not by trying to cancel it from `show`. Cancellation by pid or
# by token both lost the same race: the icon and the panel are separate
# windows, so leaving one and entering the other fires two invocations in the
# same millisecond, and neither can rely on observing the other's bookkeeping.
# The pointer's position is unambiguous, and it is the thing we actually mean.

CONFIG="$HOME/.config/eww"
STATE="/tmp/.eww_player_hover.state"
GRACE=0.3   # absorbs the spurious leaves GTK fires when crossing onto buttons
ANIM=0.25   # must outlast the revealer's transition, or the window dies mid-slide

# X reports WINDOW=0 for these override-redirect windows, so identifying them
# by id is not an option; their rectangles are. PAD bridges the bare strip
# between the icon and the panel, which the pointer crosses on its way down.
pointer_over_player() {
  local X Y PAD=30
  eval "$(xdotool getmouselocation --shell 2>/dev/null)" || return 1
  xwininfo -root -tree 2>/dev/null |
    grep -E '"Eww - player-(trigger|panel)"' |
    sed -E 's/.*\) +([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+).*/\1 \2 \3 \4/' |
    while read -r w h wx wy; do
      (( X >= wx && X < wx + w && Y >= wy && Y < wy + h + PAD )) && exit 0
    done
}

case "$1" in
  show)
    [[ -f "$STATE" ]] && exit 0
    : > "$STATE"
    eww -c "$CONFIG" open player-panel 2>/dev/null
    sleep 0.05  # let the window realize collapsed, so the reveal animates
    eww -c "$CONFIG" update player-hover=true
    ;;

  hide)
    [[ -f "$STATE" ]] || exit 0
    (
      sleep "$GRACE"
      pointer_over_player && exit 0
      rm -f "$STATE"
      eww -c "$CONFIG" update player-hover=false
      sleep "$ANIM"
      pointer_over_player && exit 0
      eww -c "$CONFIG" close player-panel 2>/dev/null
    ) &
    ;;

  *)
    echo "Usage: ${0##*/} {show|hide}" >&2
    exit 1
    ;;
esac
