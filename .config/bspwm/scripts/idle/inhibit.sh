#!/usr/bin/env bash
# Suspends the automatic lock, for when you are watching something and not
# touching the keyboard.
#
#   inhibit.sh toggle    turn inhibition on or off
#   inhibit.sh status    print "on" or "off", for the bar indicator
#
# All it does is drop a marker that idle_watch.sh checks on every poll.
# Earlier it turned X's own timers off, which was pointless twice over: those
# timers never fire on this machine, and nothing reads them any more.
#
# Browsers ask not to be interrupted through org.freedesktop.ScreenSaver, a
# D-Bus name nobody owns here, so their request reaches no one — this toggle
# is the way out for them.

STATE="${XDG_RUNTIME_DIR:-/tmp}/idle_inhibited"

case "$1" in
  toggle) [[ -f "$STATE" ]] && rm -f "$STATE" || : > "$STATE" ;;
  on)     : > "$STATE" ;;
  off)    rm -f "$STATE" ;;
  status) [[ -f "$STATE" ]] && echo "on" || echo "off" ;;
  *)
    echo "Usage: ${0##*/} {toggle|on|off|status}" >&2
    exit 1
    ;;
esac
