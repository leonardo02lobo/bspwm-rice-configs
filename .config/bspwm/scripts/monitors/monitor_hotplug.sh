#!/usr/bin/env bash
# Re-runs setup_monitors.sh whenever a monitor is added, removed or changes
# geometry, so plugging or unplugging the external (or toggling it with
# xrandr) needs nothing else.
#
# A single xrandr call fires a burst of events (add followed by geometry, or
# several geometry ones), so a run only starts once the burst has been quiet
# for DEBOUNCE seconds.
#
# bspwmrc starts this on every `bspc wm -r`, so a new instance takes over from
# the previous one instead of piling up listeners.

SETUP="${HOME}/.config/bspwm/scripts/monitors/setup_monitors.sh"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/bspwm_monitor_hotplug.pid"
DEBOUNCE=0.5

# Lead our own process group, so the previous instance can be stopped by
# group (its subscribe pipeline included) without touching bspwmrc's group.
(( $(ps -o pgid= -p $$) == $$ )) || exec setsid "$0" "$@"

if [[ -f "${PIDFILE}" ]]; then
  old="$(<"${PIDFILE}")"
  if [[ "${old}" =~ ^[0-9]+$ ]] &&
     grep -q monitor_hotplug "/proc/${old}/cmdline" 2>/dev/null; then
    kill -- "-${old}"
  fi
fi
echo $$ > "${PIDFILE}"

bspc subscribe monitor_add monitor_remove monitor_geometry |
  while true; do
    read -r _ || exit 0
    while read -r -t "${DEBOUNCE}" _; do :; done
    # Own session, so the bars it launches are not in our process group and
    # survive the next instance stopping this one.
    setsid -w "${SETUP}"
  done
