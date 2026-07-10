#!/bin/bash
STATE=$(LC_ALL=C pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -oP '(?<=Mute: )\S+')
echo "${STATE:-no}"
