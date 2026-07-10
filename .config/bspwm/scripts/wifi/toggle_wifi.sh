#!/bin/bash
STATE=$(LC_ALL=C nmcli radio wifi 2>/dev/null)
if [[ "$STATE" == "enabled" ]]; then
    nmcli radio wifi off && notify-send -t 2000 "WiFi" "WiFi desactivado"
else
    nmcli radio wifi on  && notify-send -t 2000 "WiFi" "WiFi activado"
fi
