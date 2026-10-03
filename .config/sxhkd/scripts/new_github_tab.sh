#!/bin/bash

# Target URL for GitHub
URL="https://github.com/Alex819964"

# 1. Find all window nodes on the current focused desktop
# We loop through them to find one that matches Google Chrome
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
    
    # 3. CRITICAL: Wait for physical keys to be released
    # This prevents modifiers (Super/Shift) from interfering with typing
    sleep 0.2
    
    # 4. Use xdotool to force the tab/URL into THIS specific window ID
    xdotool windowactivate --sync "$chrome_node"
    xdotool key --clearmodifiers ctrl+t     # Open new tab
    sleep 0.1                                # Wait for tab to initialize
    xdotool type --delay 10 "$URL"           # Type the URL with slight delay
    xdotool key Return                       # Press Enter
else
    echo "No Chrome found on this desktop. Spawning a fresh window."
    google-chrome --new-window "$URL"
fi
