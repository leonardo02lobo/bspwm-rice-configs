#!/usr/bin/env bash
# =============================================================
# ░█▀█░█▀█░█░░░█░█░█▀▄░█▀█░█▀▄
# ░█▀▀░█░█░█░░░░█░░█▀▄░█▀█░█▀▄
# ░▀░░░▀▀▀░▀▀▀░░▀░░▀▀░░▀░▀░▀░▀
# Author: FlickGMD 
# Repo: https://github.com/FlickGMD/AutoBSPWM
# Date: 2025-06-22 16:06:10
# =============================================================

killall -q polybar

while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

# Evita que las barras mueran si el proceso/terminal que invoca este
# script recibe SIGHUP/SIGTERM antes de terminar de lanzarlas todas.
trap '' HUP

# ░█▀▄░▀█▀░█▀▀░█░█░▀█▀░░░█▄█░█▀█░█▀▄░█░█░█░░░█▀▀░█▀▀
# ░█▀▄░░█░░█░█░█▀█░░█░░░░█░█░█░█░█░█░█░█░█░░░█▀▀░▀▀█
# ░▀░▀░▀▀▀░▀▀▀░▀░▀░░▀░░░░▀░▀░▀▀▀░▀▀░░▀▀▀░▀▀▀░▀▀▀░▀▀▀
#polybar log -c ~/.config/polybar/current.ini &
#polybar ethernet_status -c ~/.config/polybar/current.ini &
#polybar vpn_status -c ~/.config/polybar/current.ini & 

# One instance of every bar per connected monitor. Each bar inherits
# `monitor = ${env:MONITOR:}` from bar/main, so MONITOR picks its output.
launch_bars() {
  export MONITOR="${1}"

  # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀░█▀▀
  # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀░▀▀█
  # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀
  polybar primary -c ~/.config/polybar/workspace.ini &
  disown

  # ░█░░░█▀▀░█▀▀░▀█▀░░░█▀▄░█▀█░█▀▄
  # ░█░░░█▀▀░█▀▀░░█░░░░█▀▄░█▀█░█▀▄
  # ░▀▀▀░▀▀▀░▀░░░░▀░░░░▀▀░░▀░▀░▀░▀
  polybar updates -c ~/.config/polybar/current.ini &
  disown
  polybar date -c ~/.config/polybar/current.ini &
  disown
  polybar target_to_hack -c ~/.config/polybar/current.ini &
  disown
  polybar primary -c ~/.config/polybar/current.ini &
  disown

  # ░█▀▀░█▀█░█▀█░▀█▀░█▀█░▀█▀░█▀█░█▀▀░█▀▄░░░█▀▀░█▀▄░█▀█░█▄█░█▀▀
  # ░█░░░█░█░█░█░░█░░█▀█░░█░░█░█░█▀▀░█▀▄░░░█▀▀░█▀▄░█▀█░█░█░█▀▀
  # ░▀▀▀░▀▀▀░▀░▀░░▀░░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░░░▀░░░▀░▀░▀░▀░▀░▀░▀▀▀
  polybar principal_bar -c ~/.config/polybar/current.ini &
  disown
}

# `--list-monitors` only lists active outputs, so a connected but
# disabled monitor (xrandr --off) gets no bars.
for monitor in $(polybar --list-monitors | cut -d: -f1); do
  launch_bars "${monitor}"
done
