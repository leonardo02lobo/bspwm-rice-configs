#!/usr/bin/env bash
# Toggles the automatic lock, for when you are watching something and not
# touching the keyboard.
#
#   inhibit.sh toggle    turn inhibition on or off
#   inhibit.sh status    print "on" or "off", for the bar indicator
#
# Works by turning X's own idle timer off, which is what xss-lock listens to,
# so nothing needs to know about this script except the bar.
#
# Browsers ask not to be interrupted through org.freedesktop.ScreenSaver, a
# D-Bus name nobody owns on this machine, so their request reaches no one —
# this toggle is the way out for them. mpv needs no help: it suspends X's
# timer through the screensaver extension by itself.

STATE="${XDG_RUNTIME_DIR:-/tmp}/idle_inhibited"

# Mirrors the timers bspwmrc sets, so turning inhibition off restores them.
SCREENSAVER_TIMEOUT=300
DPMS_TIMEOUT=900

inhibit_on() {
  xset s off
  xset -dpms
  : > "$STATE"
}

inhibit_off() {
  xset s "$SCREENSAVER_TIMEOUT"
  xset +dpms
  xset dpms "$DPMS_TIMEOUT" "$DPMS_TIMEOUT" "$DPMS_TIMEOUT"
  rm -f "$STATE"
}

case "$1" in
  toggle) [[ -f "$STATE" ]] && inhibit_off || inhibit_on ;;
  on)     inhibit_on ;;
  off)    inhibit_off ;;
  status) [[ -f "$STATE" ]] && echo "on" || echo "off" ;;
  *)
    echo "Usage: ${0##*/} {toggle|on|off|status}" >&2
    exit 1
    ;;
esac
