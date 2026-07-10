#!/bin/bash
SSID=$(LC_ALL=C nmcli -t -f ACTIVE,SSID dev wifi list 2>/dev/null \
    | grep '^yes' | cut -d: -f2 | head -1)

LC_ALL=C nmcli dev disconnect wlan0 2>/dev/null \
    && notify-send -t 3000 "WiFi" "Desconectado de $SSID" \
    || notify-send -t 3000 "WiFi" "No estaba conectado"
