#!/bin/bash
# timeout guards against eww hanging forever waiting on an IPC reply that
# never arrives (e.g. if the daemon fails to render the window) — without it,
# every click leaves behind an unkillable-by-normal-means zombie process.
timeout 5s eww -c ~/.config/eww open --toggle wifi
