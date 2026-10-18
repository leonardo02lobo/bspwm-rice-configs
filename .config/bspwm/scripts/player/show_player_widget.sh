#!/bin/bash
# Toggles the Spotify panel below the Polybar bar.
#
# --screen follows X's primary output because that is what Polybar itself
# does: the bars launch.sh actually starts (current.ini, workspace.ini) leave
# `monitor` empty, so they land on the primary. Pinning the panel to a fixed
# output would strand it on a screen with no bar as soon as a second monitor
# becomes primary.
#
# Every eww call goes through eww_call.sh: it starts the daemon when it is not
# up, bounds the call with a timeout, and keeps a failed `open` from forking
# into a second daemon.

screen="$(xrandr --query | awk '/ connected primary/ {print $1; exit}')"
[[ -n "$screen" ]] || screen="$(xrandr --query | awk '/ connected/ {print $1; exit}')"

"$HOME/.config/bspwm/scripts/lib/eww_call.sh" open --toggle --screen "$screen" music
