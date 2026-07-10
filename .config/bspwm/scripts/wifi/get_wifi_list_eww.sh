#!/bin/bash
# Generates EWW yuck literal markup for the WiFi network list.
# SSIDs are hex-encoded to avoid quoting issues in the onclick handler.

WIFI_ENABLED=$(LC_ALL=C nmcli radio wifi 2>/dev/null)

if [[ "$WIFI_ENABLED" != "enabled" ]]; then
    echo "(label :class \"wifi-list-empty\" :text \"WiFi desactivado\")"
    exit 0
fi

# Get active network first, then others sorted by signal strength
ACTIVE_NET=$(LC_ALL=C nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE dev wifi list 2>/dev/null | grep ':yes$')
ACTIVE_SSID=$(echo "$ACTIVE_NET" | cut -d: -f1)
OTHER_NETS=$(LC_ALL=C nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE dev wifi list 2>/dev/null \
    | grep ':no$' \
    | grep -v "^${ACTIVE_SSID}:" \
    | sort -t: -k2 -rn \
    | awk -F: '!seen[$1]++')

ALL_NETS=$(printf '%s\n%s\n' "$ACTIVE_NET" "$OTHER_NETS")

if [[ -z "$(echo "$ALL_NETS" | tr -d '\n')" ]]; then
    echo "(label :class \"wifi-list-empty\" :text \"Sin redes disponibles\")"
    exit 0
fi

echo "(box :class \"wifi-list\" :orientation \"v\" :space-evenly false :spacing 2"

while IFS= read -r LINE; do
    [[ -z "$LINE" ]] && continue

    SSID=$(echo "$LINE" | cut -d: -f1)
    SIGNAL=$(echo "$LINE" | cut -d: -f2)
    SECURITY=$(echo "$LINE" | cut -d: -f3)
    ACTIVE=$(echo "$LINE" | rev | cut -d: -f1 | rev)

    [[ -z "$SSID" ]] && continue

    # Escape backslashes and double quotes so the SSID can't break out of the
    # yuck string literal (a malformed literal makes the eww daemon fail to
    # reply to the client, which then hangs forever instead of exiting).
    SSID_ESCAPED=$(printf '%s' "$SSID" | sed 's/\\/\\\\/g; s/"/\\"/g')

    # Signal icon (4 levels)
    if   [[ "$SIGNAL" -ge 75 ]]; then SIG_ICON="󰤨"
    elif [[ "$SIGNAL" -ge 50 ]]; then SIG_ICON="󰤥"
    elif [[ "$SIGNAL" -ge 25 ]]; then SIG_ICON="󰤢"
    else                               SIG_ICON="󰤟"
    fi

    # Security icon
    if [[ -z "$SECURITY" || "$SECURITY" == "--" ]]; then
        SEC_ICON="󰌿"; SEC_CLASS="wifi-open"
    else
        SEC_ICON="󰌾"; SEC_CLASS="wifi-secure"
    fi

    # Hex-encode SSID to safely pass it in onclick
    SSID_HEX=$(printf '%s' "$SSID" | hexdump -v -e '1/1 "%02x"')
    CONNECT_SCRIPT="~/.config/bspwm/scripts/wifi/connect_wifi.sh"
    DISCONNECT_SCRIPT="~/.config/bspwm/scripts/wifi/disconnect_wifi.sh"

    if [[ "$ACTIVE" == "yes" ]]; then
        ITEM_CLASS="wifi-item active"
        BTN_CLASS="wifi-btn disconnect-btn"
        BTN_TEXT="Desconectar"
        ONCLICK="${DISCONNECT_SCRIPT}"
    else
        ITEM_CLASS="wifi-item"
        BTN_CLASS="wifi-btn connect-btn"
        BTN_TEXT="Conectar"
        ONCLICK="${CONNECT_SCRIPT} ${SSID_HEX}"
    fi

    echo "  (box :class \"${ITEM_CLASS}\" :space-evenly false :spacing 8 :hexpand true"
    echo "    (label :class \"wifi-sig ${SIG_ICON}\" :text \"${SIG_ICON}\")"
    echo "    (label :class \"wifi-sec ${SEC_CLASS}\" :text \"${SEC_ICON}\")"
    echo "    (label :class \"wifi-ssid-item\" :text \"${SSID_ESCAPED}\" :hexpand true :halign \"start\" :limit-width 18)"
    echo "    (button :class \"${BTN_CLASS}\" :onclick \"${ONCLICK}\" \"${BTN_TEXT}\")"
    echo "  )"

done <<< "$ALL_NETS"

echo ")"
