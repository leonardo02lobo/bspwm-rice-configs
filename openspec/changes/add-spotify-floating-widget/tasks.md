## 1. Dependencia

- [x] 1.1 Instalar `playerctl` (`sudo apt install playerctl`) y verificar con `playerctl --version`
- [x] 1.2 Con Spotify abierto y reproduciendo, comprobar la salida de `playerctl -p spotify metadata title`, `artist`, `status`, `position`, `shuffle` y `loop`
- [x] 1.3 Comprobar con Spotify cerrado el código de salida y el stderr de `playerctl -p spotify status`, para fijar la implementación del centinela `Offline`

## 2. Capa de control

- [x] 2.1 Reescribir `.config/sxhkd/scripts/spotify_control` sobre `playerctl`, con el nombre del reproductor en una variable y los subcomandos `playpause`, `play`, `next`, `previous`, `stop`, `seek-forward`, `seek-backward`, `shuffle` y `repeat`
- [x] 2.2 Implementar `repeat` sin argumento como ciclo `None → Playlist → Track → None`, y con argumento explícito como fijación de ese estado
- [x] 2.3 Implementar `seek-forward` / `seek-backward` con salto de 8 segundos, equivalente al `int64:8000000` de los `dbus-send` actuales
- [x] 2.4 Implementar la degradación sin Spotify: sin ruido en stderr, sin procesos colgados
- [x] 2.5 Devolver código distinto de cero y mensaje de uso en stderr ante un subcomando desconocido
- [x] 2.6 Conservar el permiso de ejecución del script

## 3. Lectura de estado para el widget

- [x] 3.1 Crear `.config/bspwm/scripts/player/get_player_state.sh`, que emite en una sola línea un JSON con estado, título, artista, shuffle, repeat, y posición y duración en segundos y en `m:ss`
- [x] 3.2 Construir el JSON con `jq` para que títulos con comillas o barras no rompan la salida
- [x] 3.3 Devolver estado `Offline` y metadata vacía, con código de salida cero, cuando no hay reproductor
- [x] 3.4 Dar permiso de ejecución y verificar la salida con Spotify corriendo y cerrado, comprobando que es JSON válido y que nada escribe en stderr

## 4. Atajos de teclado

- [x] 4.1 Corregir en `sxhkdrc` la ruta de `XF86AudioStop`, `XF86AudioPrev` y `XF86AudioNext`, que hoy omiten el directorio `scripts/`
- [x] 4.2 Migrar `super + F11` y `super + F10` de `dbus-send` crudo a `spotify_control seek-forward` / `seek-backward`
- [x] 4.3 Migrar `super + Pause` y `super + Delete` a `spotify_control repeat Playlist` / `repeat Track`
- [ ] 4.4 Sincronizar a `~/.config/`, recargar sxhkd y verificar las cuatro teclas multimedia y los cuatro atajos migrados con Spotify sin foco

## 5. Corrección del cableado del widget

- [x] 5.1 Descruzar en `player.yuck` los `defpoll` `shuffle` y `loop`, que hoy ejecutan la consulta del otro
- [x] 5.2 Sustituir `music-positions` por una consulta real de posición, de modo que la escala deje de usar la duración como valor
- [x] 5.3 Unificar unidades de posición y duración y formatearlas como `m:ss`, eliminando los `defpoll` duplicados de `mpris:length`
- [x] 5.4 Sustituir en los `:onclick` las llamadas directas a `playerctl` por invocaciones a `spotify_control`
- [x] 5.5 Añadir el estado "sin reproductor activo" cuando el estado es `Offline`, sin mostrar metadata residual

## 6. Reubicación de la ventana

- [x] 6.1 Cambiar la geometría de `defwindow music` de `:y "-7%"` / `:anchor "bottom center"` a `:y "46px"` / `:anchor "top right"`
- [x] 6.2 Revisar `:wm-ignore`, `:focusable` y `:stacking` para que el panel se comporte como el de WiFi y quede por encima de las ventanas

## 7. Apertura del panel

- [x] 7.1 Crear `.config/bspwm/scripts/player/show_player_widget.sh` siguiendo el patrón de `show_wifi_widget.sh`, con `timeout 5s` y `-c ~/.config/eww` explícito para no hablarle al daemon de `display-manager`
- [x] 7.2 Resolver el output en el script: `eDP` si está conectado, `HDMI-2` en caso contrario, pasándolo a `eww open` con `--screen`
- [x] 7.3 Dar permiso de ejecución y añadir el atajo `super + ctrl + s` en `sxhkdrc`
- [x] 7.4 Sincronizar, recargar y verificar que el panel abre y cierra con el atajo, y que queda bajo la barra sin taparla

## 8. Limpieza de Polybar (fuera del repo)

- [ ] 8.1 Retirar `[module/mpd]` y `[module/mpd_control]` de `~/.config/polybar/modules.ini`
- [ ] 8.2 Retirar la referencia comentada a `mpd_bar` en `modules-left` de `~/.config/polybar/config.ini`
- [ ] 8.3 Relanzar Polybar y verificar que la barra sigue renderizando con todos sus módulos

## 9. Documentación y verificación final

- [x] 9.1 Documentar en `README.md` el widget, el atajo `super + ctrl + s`, la dependencia `playerctl` y el acoplamiento del offset de 46px con `height = 42` de `bar/main`
- [x] 9.2 Documentar en `README.md` que `~/.config/polybar/` no está versionado y que su limpieza es manual
- [ ] 9.3 Verificar el flujo completo: abrir el panel, cambiar de pista desde el panel y desde las teclas, y comprobar que la metadata se refresca en ambos casos
- [ ] 9.4 Verificar el panel con Spotify cerrado: abre, muestra el estado vacío y los clics no producen errores
