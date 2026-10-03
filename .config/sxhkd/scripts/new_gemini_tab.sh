#!/bin/bash

URL="https://gemini.google.com"

# 1. Locate Chrome on current desktop
chrome_node=""
for node in $(bspc query -N -d focused -n .window); do
    if xprop -id "$node" WM_CLASS 2>/dev/null | grep -qi "google-chrome"; then
        chrome_node="$node"
        break
    fi
done

if [ -n "$chrome_node" ]; then
    # 2. Focus the window
    bspc node "$chrome_node" -f
    
    # 3. CRITICAL: Wait for physical keys (Super/Shift/Z) to be released
    # This prevents 'h' from becoming 'Super+h' and locking your session
    while [ -n "$(xdotool search --id "$chrome_node" getwindowfocus)" ] && \
          xkbcli interactive-wayland 2>/dev/null | grep -q "pressed"; do sleep 0.05; done 
    # Simplified version for X11:
    sleep 0.3 

    # 4. Inject keystrokes using the window ID specifically
    xdotool windowactivate --sync "$chrome_node"
    xdotool key --clearmodifiers ctrl+t
    sleep 0.2
    xdotool type --delay 10 "$URL"
    xdotool key Return
else
    google-chrome --new-window "$URL"
fi
