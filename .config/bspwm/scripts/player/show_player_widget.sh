#!/bin/bash
# Toggles the Spotify panel below the Polybar bar.
#
# -c is explicit because a second eww daemon runs on this machine (bspwmrc
# starts one for the display-manager widget), and a bare `eww` can reach it.
#
# --screen follows X's primary output because that is what Polybar itself
# does: the bars launch.sh actually starts (current.ini, workspace.ini) leave
# `monitor` empty, so they land on the primary. Pinning the panel to a fixed
# output would strand it on a screen with no bar as soon as a second monitor
# becomes primary.
#
# timeout guards against eww hanging forever waiting on an IPC reply that never
# arrives — without it, every keypress leaves behind a zombie process.

CONFIG="$HOME/.config/eww"

screen="$(xrandr --query | awk '/ connected primary/ {print $1; exit}')"
[[ -n "$screen" ]] || screen="$(xrandr --query | awk '/ connected/ {print $1; exit}')"

timeout 5s eww -c "$CONFIG" open --toggle --screen "$screen" music
