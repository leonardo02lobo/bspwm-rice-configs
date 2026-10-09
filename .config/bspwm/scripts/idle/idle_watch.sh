#!/usr/bin/env bash
# Drives the three idle stages by polling how long the session has been idle.
#
# X's own idle machinery is inert on this machine: the screensaver timer
# reaches zero and never activates, and the DPMS timers never fire either
# (measured — 103s of idle against a 15s timeout, monitor still on). Only the
# idle counter is trustworthy, so every stage is triggered from here instead
# of being left to the server, and DPMS is forced rather than scheduled.
#
# Locking before suspend is not this script's job: xss-lock still does that
# half, with --ignore-xss, because its logind integration works fine.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDLE_MS="$HERE/idle_ms.py"
SCREENSAVER="$HERE/screensaver.sh"
LOCK="$HERE/lock.sh"
INHIBITED="${XDG_RUNTIME_DIR:-/tmp}/idle_inhibited"

SCREENSAVER_AT=${SCREENSAVER_AT:-300}   # seconds idle before the idle screen
LOCK_AT=${LOCK_AT:-600}                 # before the session locks
DPMS_AT=${DPMS_AT:-900}                 # before the panel is powered off
POLL=${POLL:-5}

screensaver_pid=""
lock_pid=""
blanked=false

stop_screensaver() {
  [[ -n "$screensaver_pid" ]] || return
  kill -TERM "$screensaver_pid" 2>/dev/null
  screensaver_pid=""
}

locked() { [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; }

cleanup() { stop_screensaver; exit 0; }
trap cleanup TERM INT

# X's own timers are left off: neither the screensaver nor DPMS ever fires
# here, and leaving them set would only invite someone to trust them later.
# DPMS stays enabled so the panel can still be powered off on demand.
xset s off
xset +dpms
xset dpms 0 0 0

while true; do
  idle=$(( $("$IDLE_MS") / 1000 ))

  # Players suspending the X screensaver cannot be detected here: this server
  # reports the saver's state as Off throughout an XScreenSaverSuspend, and
  # the idle counter climbs right through it. Video of any kind needs the
  # manual toggle.
  if [[ -f "$INHIBITED" ]]; then
    stop_screensaver
    sleep "$POLL"
    continue
  fi

  if locked; then
    # Typing a password counts as input, so idle cannot be trusted to keep
    # growing while locked; the panel is blanked once and left alone.
    if ! $blanked && (( idle >= DPMS_AT - LOCK_AT )); then
      xset dpms force off
      blanked=true
    fi
    sleep "$POLL"
    continue
  fi

  if (( idle >= LOCK_AT )); then
    stop_screensaver
    "$LOCK" &
    lock_pid=$!
    blanked=false
  elif (( idle >= SCREENSAVER_AT )); then
    if [[ -z "$screensaver_pid" ]] || ! kill -0 "$screensaver_pid" 2>/dev/null; then
      "$SCREENSAVER" &
      screensaver_pid=$!
    fi
  else
    stop_screensaver
  fi

  sleep "$POLL"
done
