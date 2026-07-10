#!/bin/bash
# Configures the touchpad for a proper laptop-like experience in BSPWM.
# Enables tap-to-click, two-finger right-click, natural scrolling,
# two-finger scroll, and disable-while-typing.

XINPUT_BIN="$(command -v xinput 2>/dev/null)"

if [[ -z "$XINPUT_BIN" ]]; then
    echo "[touchpad] xinput not found. Install it with: sudo apt install xinput" >&2
    echo "[touchpad] The persistent X11 config in /etc/X11/xorg.conf.d/90-touchpad-libinput.conf will apply after restarting Xorg." >&2
    exit 0
fi

get_touchpad_id() {
    xinput list 2>/dev/null | grep -iE "touchpad|synaptics|glidepoint" | grep -o 'id=[0-9]*' | head -1 | cut -d= -f2
}

TP_ID=$(get_touchpad_id)

if [[ -z "$TP_ID" ]]; then
    echo "[touchpad] No touchpad detected." >&2
    exit 0
fi

TP_NAME=$(xinput list --name-only "$TP_ID" 2>/dev/null)
echo "[touchpad] Found touchpad: $TP_NAME (id=$TP_ID)"

# Enable tapping (tap-to-click)
xinput set-prop "$TP_ID" "libinput Tapping Enabled" 1 2>/dev/null || true

# Two-finger tap = right click, three-finger tap = middle click
xinput set-prop "$TP_ID" "libinput Tapping Button Mapping Enabled" 1 2 3 2>/dev/null || true

# Use clickfinger method: one finger left, two fingers right, three fingers middle
xinput set-prop "$TP_ID" "libinput Click Method Enabled" 0 1 2>/dev/null || true

# Enable natural scrolling
xinput set-prop "$TP_ID" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true

# Two-finger scroll
xinput set-prop "$TP_ID" "libinput Scroll Method Enabled" 0 0 1 2>/dev/null || true

# Disable touchpad while typing
xinput set-prop "$TP_ID" "libinput Disable While Typing Enabled" 1 2>/dev/null || true

# Enable tap-and-drag
xinput set-prop "$TP_ID" "libinput Tapping Drag Enabled" 1 2>/dev/null || true

# Disable tap drag lock (lift finger to stop dragging)
xinput set-prop "$TP_ID" "libinput Tapping Drag Lock Enabled" 0 2>/dev/null || true

# Acceleration speed (0 = default)
xinput set-prop "$TP_ID" "libinput Accel Speed" 0.0 2>/dev/null || true

echo "[touchpad] Touchpad configured successfully."
