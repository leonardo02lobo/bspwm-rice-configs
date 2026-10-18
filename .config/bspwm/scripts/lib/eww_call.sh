#!/usr/bin/env bash
# The one way this rice talks to the eww daemon of ~/.config/eww.
#
#   eww_call.sh open volume
#   eww_call.sh update vol-level=42
#   eww_call.sh close volume
#
# Exit status and output are eww's own, so callers need not know this is here.
#
# --no-daemonize is the point of the script. When `eww open` cannot forward
# its command, the client forks itself into a daemon and serves the request on
# its own (main.rs:155), and on the way up it unlinks the socket and rebinds
# it (main.rs:159). The daemon that was already running stays alive with its
# windows still mapped and nothing able to reach them: that is how a
# fullscreen idle screen ends up stuck over the session, and how a volume OSD
# sits on the desktop for hours. Only `open` and `open-many` do this
# (opts.rs:260), and the flag turns it off, so a failed call just fails.
#
# A timeout cannot clean that up, which is why one was not enough on its own:
# the forked daemon detaches to ppid 1 and the foreground process exits
# successfully, leaving nothing to kill. The timeout below is for the other
# failure — a request the daemon never answers — where it is the only guard.
#
# With the fallback off, nothing starts the daemon on demand any more, so this
# script does, and under a lock: the volume keys, the hover trigger and the
# idle watcher can all call at the same moment, and each would otherwise start
# a daemon of its own and recreate the mess the flag prevents.

set -u

readonly SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${BASH_SOURCE[0]##*/}"
readonly CONFIG="${HOME}/.config/eww"
readonly LOCK="${XDG_RUNTIME_DIR:-/tmp}/eww_call.lock"
readonly TIMEOUT="${EWW_CALL_TIMEOUT:-5s}"
readonly START_WAIT=10   # seconds to give a daemon we just started

run_eww() { timeout "$TIMEOUT" eww --no-daemonize -c "$CONFIG" "$@"; }

# `ping` is answered before the daemon can actually serve a window command, so
# a restart that waited on it handed back a daemon that then failed the very
# `open` it was started for. active-windows goes through the application
# thread, which is the part that has to be up.
daemon_up() { timeout 2s eww --no-daemonize -c "$CONFIG" active-windows >/dev/null 2>&1; }

# Every eww process working on this config, daemon or not. The session's
# second daemon (display-manager) has its own config path and never matches.
config_pids() {
  local pid cmdline
  for pid in $(pgrep -x eww 2>/dev/null); do
    cmdline="$(tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null)" || continue
    [[ "$cmdline" == *"$CONFIG"* ]] && printf '%s\n' "$pid"
  done
}

# An eww process listening on a socket is a daemon, whatever its command line
# says, so this also counts a client that forked itself into one. Two of them
# on one config is never right: the one that lost the socket is sitting there
# deaf, still holding its windows, and nothing can close them.
daemons_here() {
  local here listening pid
  here="$(config_pids)"
  listening="$(ss -xlp 2>/dev/null | grep -F '/eww-server_' | grep -o 'pid=[0-9]*' | cut -d= -f2)"
  for pid in $listening; do
    grep -qxF "$pid" <<< "$here" && printf '%s\n' "$pid"
  done
}

# eww does not remove its socket on the way out, and a new daemon will not
# bind over the leftover. Going by who is listening rather than by name is
# what keeps this from deleting the display-manager daemon's socket.
drop_stale_sockets() {
  local socket listeners
  listeners="$(ss -xl 2>/dev/null | awk '{print $5}')"
  for socket in "${XDG_RUNTIME_DIR:-/tmp}"/eww-server_*; do
    [[ -e "$socket" ]] || continue
    grep -qxF -- "$socket" <<< "$listeners" || rm -f "$socket"
  done
}

# The body of a restart. It holds no lock of its own because it only ever runs
# as the command of the `flock -o` further down.
do_restart() {
  local pid i

  # Whoever held the lock before this call may have fixed it already.
  (( $(daemons_here | wc -l) == 1 )) && daemon_up && return 0

  # Anything still alive on this config has lost the socket and answers
  # nothing. Its windows go with it; the caller reopens what it needs.
  for pid in $(config_pids); do kill "$pid" 2>/dev/null; done
  sleep 0.3
  for pid in $(config_pids); do kill -9 "$pid" 2>/dev/null; done
  drop_stale_sockets

  setsid eww -c "$CONFIG" daemon >/dev/null 2>&1 </dev/null &
  for (( i = 0; i < START_WAIT * 4; i++ )); do
    daemon_up && return 0
    sleep 0.25
  done
  return 1
}

# Re-entry point for the flock below, so it must come before anything else
# runs.
if [[ "${1:-}" == "--restart-daemon" ]]; then
  do_restart
  exit
fi

# -o closes the lock file before running the command, so the daemon started
# inside cannot inherit it. That matters more than it looks: a descriptor
# holds a flock whether or not anyone meant it to, and bash duplicates the
# descriptor to a high number when it sets up a redirection of its own, so
# closing fd 8 by hand still leaked the copy — and one leaked copy wedges
# every later call for the life of the daemon. setup_monitors.sh closes its
# own lock the same way before launching the bars.
restart_daemon() { flock -o "$LOCK" "$SELF" --restart-daemon; }
start_daemon()   { daemon_up || restart_daemon; }

(( $# )) || { echo "Uso: ${0##*/} <orden de eww...>" >&2; exit 2; }

# A second daemon answers normally, so no call would fail and nothing would
# notice the deaf one. This is the only check that costs anything on every
# call, and it is one `ss` against an IPC round trip.
if (( $(daemons_here | wc -l) > 1 )); then
  restart_daemon || true
fi

# Try first and ask questions later: a healthy daemon costs nothing extra, and
# pinging before every call would double the round trips on the hover path,
# which fires many times a second. This attempt's stderr is dropped because a
# cold start is expected to fail here; the retry below reports a real error as
# itself.
run_eww "$@" 2>/dev/null && exit 0

# The failure may only mean there is no daemon listening yet. Start one and
# retry exactly once, so a real error — a window name that does not exist —
# surfaces as itself instead of looping. start_daemon returns at once when the
# daemon is in fact healthy, so a genuine error costs one ping, not a restart.
start_daemon || { echo "${0##*/}: el daemon de eww no arranca" >&2; exit 1; }
run_eww "$@"
