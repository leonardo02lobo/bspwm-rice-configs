#!/bin/bash
LC_ALL=C pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null \
    | grep -oP '\d+(?=%)' | head -1 \
    || echo "0"
