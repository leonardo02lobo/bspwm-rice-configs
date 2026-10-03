#!/bin/bash
# Muestra el OSD de volumen y lo cierra tras 3s de inactividad.
#
# - Empuja el estado actual a eww (push, no poll): el valor mostrado es
#   exacto en el momento del cambio, sin lag de 500ms.
# - Mantiene UN solo timer de auto-cierre: cada pulsación cancela el timer
#   anterior (y su `sleep`) antes de armar uno nuevo, de modo que no se
#   acumula un enjambre de procesos en segundo plano.

DIR="$HOME/.config/bspwm/scripts/volume"
PIDFILE="/tmp/.eww_volume_timer.pid"

# Abre la ventana (arranca el daemon si hace falta; no-op si ya está abierta)
eww open volume

# Empuja el estado real al widget
vol=$("$DIR/get_volume.sh")
mute=$("$DIR/get_mute.sh")
eww update vol-level="$vol" vol-muted="$mute"

# Cancela el timer de auto-cierre anterior y su `sleep` hijo, si siguen vivos
if [[ -f "$PIDFILE" ]]; then
  old="$(cat "$PIDFILE" 2>/dev/null)"
  if [[ -n "$old" ]]; then
    pkill -P "$old" 2>/dev/null   # el `sleep` hijo
    kill "$old"     2>/dev/null   # el subshell del timer
  fi
fi

# Arma exactamente un nuevo timer de auto-cierre
( sleep 3; eww close volume ) &
echo $! > "$PIDFILE"
