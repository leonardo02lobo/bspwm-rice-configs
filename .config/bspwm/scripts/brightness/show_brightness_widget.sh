#!/bin/bash
# timeout acota una petición IPC que se queda sin respuesta: sin él la llamada
# espera para siempre y el script nunca llega al resto.
#
# Ojo: NO evita el otro fallo, medido en eww 0.6.0 — un cliente que no logra
# reenviar su orden se convierte él mismo en daemon y se desliga (ppid 1). Sale
# con éxito, así que timeout no tiene a quién matar, y queda un segundo daemon
# peleándose por el socket. Eso sigue pendiente.
EWW=(timeout 5s eww -c "$HOME/.config/eww")

STAMP_FILE="/tmp/.eww_brightness_stamp"
STAMP=$(date +%s%N)
echo "$STAMP" > "$STAMP_FILE"

"${EWW[@]}" open brightness

(
  MY_STAMP="$STAMP"
  sleep 3
  if [[ "$(cat "$STAMP_FILE" 2>/dev/null)" == "$MY_STAMP" ]]; then
    "${EWW[@]}" close brightness
  fi
) &
