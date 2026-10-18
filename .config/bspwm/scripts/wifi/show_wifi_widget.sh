#!/bin/bash
# Every eww call goes through eww_call.sh: it starts the daemon when it is not
# up, bounds the call with a timeout, and keeps a failed `open` from forking
# into a second daemon.
"$HOME/.config/bspwm/scripts/lib/eww_call.sh" open --toggle wifi
