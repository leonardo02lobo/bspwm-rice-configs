#!/usr/bin/env bash
# Shows the idle screen on every connected output.
#
# Runs as xss-lock's notifier, which means it is started when the session goes
# idle and killed when activity returns or when the locker takes over. The
# SIGTERM trap is the whole reason this script exists as a long-lived process:
# without it, fullscreen windows would be left sitting on top of the session
# with nothing left to close them.
#
# Outputs are enumerated here rather than in setup_monitors.sh because these
# windows are transient. setup_monitors.sh owns the permanent ones — bars and
# triggers — and has no business knowing whether the session is idle.

# Every eww call goes through eww_call.sh: it starts the daemon when it is not
# up, bounds the call with a timeout, and keeps a failed `open` from forking
# into a second daemon.
#
# The timeout matters more here than anywhere else: bash runs no trap while a
# foreground command has not returned, so a call that never answers would
# swallow the SIGTERM idle_watch.sh sends and leave the fullscreen window up,
# out of reach of both pointer and WM.
EWW=("$HOME/.config/bspwm/scripts/lib/eww_call.sh")
ids=()

cleanup() {
  trap - TERM INT EXIT
  for id in "${ids[@]}"; do
    "${EWW[@]}" close "$id" 2>/dev/null
  done
  exit 0
}
trap cleanup TERM INT EXIT

while read -r output; do
  [[ -n "$output" ]] || continue
  id="screensaver-$output"
  ids+=("$id")
  "${EWW[@]}" open --id "$id" --screen "$output" screensaver 2>/dev/null
done < <(xrandr --query | awk '/ connected/ {print $1}')

# Nothing to do but stay alive and wait to be killed. `sleep &` plus `wait`
# rather than a bare `sleep`, so the trap fires immediately instead of after
# the sleep finishes.
while true; do
  sleep 3600 &
  wait $!
done
