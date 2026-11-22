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
#
# Two things hold the stages off: the manual toggle (inhibit.sh) and video
# actually playing (video_playing.sh). Both discount the time they cover, so
# the countdown restarts from zero when they stop rather than firing at once.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDLE_MS="$HERE/idle_ms.py"
SCREENSAVER="$HERE/screensaver.sh"
LOCK="$HERE/lock.sh"
VIDEO="$HERE/video_playing.sh"
INHIBITED="${XDG_RUNTIME_DIR:-/tmp}/idle_inhibited"

SCREENSAVER_AT=${SCREENSAVER_AT:-1800}  # seconds idle before the idle screen (30 min)
LOCK_AT=${LOCK_AT:-3600}                # before the session locks (1 hour)
DPMS_AT=${DPMS_AT:-3900}                # before the panel is powered off (5 min after lock)
POLL=${POLL:-5}

screensaver_pid=""
lock_pid=""
blanked=false
held=0         # idle seconds that passed while the stages were being held off
locked_at=0    # wall clock when the locker took over

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

  # Real input drops the counter below what has already been discounted,
  # which is how the discount clears itself.
  (( idle < held )) && held=0

  if [[ -f "$INHIBITED" ]]; then
    held=$idle
    stop_screensaver
    sleep "$POLL"
    continue
  fi

  if locked; then
    # Measured from when the locker took over, on the wall clock, because the
    # idle counter is no use here twice over: typing a password resets it, and
    # it has already passed LOCK_AT by the time we lock — comparing it against
    # the absolute threshold blanked the panel in the same poll as the lock,
    # which put the third stage at ten minutes instead of the fifteen it is
    # supposed to be.
    if ! $blanked && (( $(date +%s) - locked_at >= DPMS_AT - LOCK_AT )); then
      xset dpms force off
      blanked=true
    fi
    sleep "$POLL"
    continue
  fi

  # Video on screen counts as activity. The time it ran is discounted rather
  # than the stages merely skipped: skipping alone would leave the counter
  # sitting above LOCK_AT, and a two-hour film would lock the session on the
  # very next poll after it ended.
  #
  # X cannot tell us this. Players announce it through XScreenSaverSuspend and
  # org.freedesktop.ScreenSaver, and this machine honours neither — measured.
  if "$VIDEO"; then
    held=$idle
    stop_screensaver
    sleep "$POLL"
    continue
  fi

  waited=$(( idle - held ))

  if (( waited >= LOCK_AT )); then
    stop_screensaver
    "$LOCK" &
    lock_pid=$!
    locked_at=$(date +%s)
    blanked=false
  elif (( waited >= SCREENSAVER_AT )); then
    if [[ -z "$screensaver_pid" ]] || ! kill -0 "$screensaver_pid" 2>/dev/null; then
      "$SCREENSAVER" &
      screensaver_pid=$!
    fi
  else
    stop_screensaver
  fi

  sleep "$POLL"
done
