#!/bin/bash
# Toggles the Spotify panel below the Polybar bar.
#
# -c is explicit because a second eww daemon runs on this machine (bspwmrc
# starts one for the display-manager widget), and a bare `eww` can reach it.
#
# --screen mirrors Polybar's own output selection instead of trusting X's
# primary: Polybar pins bar/main to eDP and falls back to HDMI-2, so following
# primary would float the panel under a bar that isn't there.
#
# timeout guards against eww hanging forever waiting on an IPC reply that never
# arrives — without it, every keypress leaves behind a zombie process.

CONFIG="$HOME/.config/eww"

screen="HDMI-2"
xrandr --query | grep -q "^eDP connected" && screen="eDP"

timeout 5s eww -c "$CONFIG" open --toggle --screen "$screen" music
