#!/usr/bin/env bash
# Locks the session. The installed i3lock is i3lock-color, so the clock and
# the indicator ring come for free.
#
# --nofork is required, not cosmetic: xss-lock tracks the locker process to
# know whether the session is still locked, and a forking locker exits
# immediately, so xss-lock would consider the screen unlocked while i3lock is
# still up — and would never lock again before suspending.
#
# No screenshot blur, although i3lock-color does it well. A blurred desktop
# still shows the shape of what was open — which windows, how many, a
# document, a conversation — and this laptop gets locked in public places.
# The wallpaper reveals nothing about the session.

WALLPAPER="$HOME/Imágenes/wallpapers/Themes/Default/logo-olas-minimalista_3840x2400_xtrafondos.com.jpg"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/i3lock"

# The whole X screen, which spans every connected monitor: the background is
# rendered once per geometry, so plugging a monitor in regenerates it instead
# of stretching yesterday's image across the new layout.
geometry="$(xdpyinfo | awk '/dimensions:/ {print $2}')"
background="$CACHE/bg-$geometry.png"

# ImageMagick 7 renamed `convert` to `magick` and warns on every call.
IM=(magick); command -v magick >/dev/null || IM=(convert)

mkdir -p "$CACHE"
if [[ ! -f "$background" ]]; then
  "${IM[@]}" "$WALLPAPER" -resize "${geometry}^" -gravity center \
    -extent "$geometry" "$background" 2>/dev/null || background=""
fi

args=(
  --nofork
  --ignore-empty-password
  --show-failed-attempts
  --clock
  --time-str "%H:%M"
  --date-str "%A %d de %B"
  --radius 90
  --ring-width 8
  --ring-color       c2f6fcff
  --inside-color      14171ccc
  --line-color        00000000
  --separator-color   14171cff
  --keyhl-color       81ae5fff
  --bshl-color        e51d0bff
  --ringver-color     81ae5fff
  --ringwrong-color   e51d0bff
  --time-color        b8bfe5ff
  --date-color        b8bfe5ff
  --verif-text        "comprobando…"
  --wrong-text        "no"
  --noinput-text      ""
)

[[ -n "$background" ]] && args+=(--image "$background") || args+=(--color 14171cff)

exec i3lock "${args[@]}"
