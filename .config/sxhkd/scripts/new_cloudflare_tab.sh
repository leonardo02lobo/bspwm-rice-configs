#!/bin/bash

# Target URL for Cloudflare Dashboard
URL="https://dash.cloudflare.com/7177a57719b5322f67413f976a108b8b/one/networks/connectors"

# 1. Find Chrome nodes on the current focused desktop
chrome_node=""
for node in $(bspc query -N -d focused -n .window); do
    CLASS=$(xprop -id "$node" WM_CLASS 2>/dev/null)
    if echo "$CLASS" | grep -qi "google-chrome"; then
        chrome_node="$node"
        break
    fi
done

if [ -n "$chrome_node" ]; then
    echo "Match found: $chrome_node. Targeting this window..."
    
    # 2. Focus the local window
    bspc node "$chrome_node" -f
    
    # 3. Wait for physical keys (Super+Shift+A) to be released
    # This prevents the letter 'h' from triggering Super+h/Shift+h conflicts
    sleep 0.2
    
    # 4. Inject navigation via xdotool
    xdotool windowactivate --sync "$chrome_node"
    xdotool key --clearmodifiers ctrl+t     # Open new tab
    sleep 0.1                                # Wait for tab focus
    xdotool type --delay 10 "$URL"           # Type the URL
    xdotool key Return                       # Press Enter
else
    echo "No Chrome found on this desktop. Spawning a fresh window."
    google-chrome --new-window "$URL"
fi
