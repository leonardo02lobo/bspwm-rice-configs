#!/bin/bash
# Receives SSID as hex-encoded string to avoid shell quoting issues.
SSID_HEX="${1}"
SSID=$(python3 -c "import sys,binascii; print(binascii.unhexlify(sys.argv[1]).decode('utf-8','replace'))" "$SSID_HEX" 2>/dev/null)

if [[ -z "$SSID" ]]; then
    notify-send -t 3000 "WiFi" "Error: SSID no recibido"
    exit 1
fi

# Try connecting with saved credentials first
RESULT=$(LC_ALL=C nmcli dev wifi connect "$SSID" 2>&1)

if echo "$RESULT" | grep -qi "Error\|failed\|No network"; then
    # Network requires password — prompt via rofi
    PASS=$(rofi -dmenu -password -l 0 -p "Password para \"$SSID\":" \
           -theme ~/.config/rofi/config.rasi 2>/dev/null)
    if [[ -n "$PASS" ]]; then
        LC_ALL=C nmcli dev wifi connect "$SSID" password "$PASS" \
            && notify-send -t 3000 "WiFi" "Conectado a $SSID" \
            || notify-send -t 3000 "WiFi" "Error al conectar a $SSID"
    fi
else
    notify-send -t 3000 "WiFi" "Conectado a $SSID"
fi
