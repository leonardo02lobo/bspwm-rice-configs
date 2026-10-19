#!/usr/bin/env bash
# Exits 0 while something is playing that puts movement on the screen, which
# is what should hold the idle stages off.
#
#   video_playing.sh        exit 0 if video is playing, 1 otherwise
#   video_playing.sh -v     same, and print the player that matched
#
# MPRIS is the signal. X cannot provide it: players ask not to be interrupted
# through XScreenSaverSuspend and org.freedesktop.ScreenSaver, and this
# machine honours neither — the saver reports Off right through a suspend, and
# the D-Bus name has no owner. Measured, both of them.
#
# The players are an allowlist, not a deny-list, and the asymmetry is
# deliberate: a video player missing from the list only brings back the old
# annoyance for that one app, while an audio player missing from a deny-list
# would quietly stop a laptop that travels from ever locking itself.
#
# Music is not movement. Spotify is left out on purpose so the panel can still
# blank while it plays. A browser playing music does count, because MPRIS
# carries nothing that separates a music tab from a video one and a tab is far
# more often a video — erring that way costs a dark screen, not a missed lock.
#
# timeout because playerctl talks over D-Bus and a wedged player would
# otherwise hang the poll loop that calls this every few seconds.

PLAYERS=${VIDEO_PLAYERS:-"mpv vlc chromium chrome firefox brave librewolf msedge totem smplayer celluloid haruna clapper"}

verbose=false
[[ "${1:-}" == "-v" ]] && verbose=true

for player in $(timeout 2s playerctl -l 2>/dev/null); do
  for known in $PLAYERS; do
    [[ "$player" == *"$known"* ]] || continue
    if [[ "$(timeout 2s playerctl -p "$player" status 2>/dev/null)" == "Playing" ]]; then
      $verbose && echo "$player"
      exit 0
    fi
    break
  done
done

exit 1
