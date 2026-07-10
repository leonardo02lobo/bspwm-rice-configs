#!/bin/bash
FIELD="${1:-all}"
case "$FIELD" in
  enabled)
    LC_ALL=C nmcli radio wifi 2>/dev/null || echo "disabled"
    ;;
  ssid)
    LC_ALL=C nmcli -t -f ACTIVE,SSID dev wifi list 2>/dev/null \
      | grep '^yes' | cut -d: -f2 | head -1 || echo ""
    ;;
  signal)
    LC_ALL=C nmcli -t -f ACTIVE,SIGNAL dev wifi list 2>/dev/null \
      | grep '^yes' | cut -d: -f2 | head -1 || echo "0"
    ;;
  ip)
    LC_ALL=C nmcli -g IP4.ADDRESS dev show wlan0 2>/dev/null \
      | head -1 | cut -d/ -f1 || echo ""
    ;;
esac
