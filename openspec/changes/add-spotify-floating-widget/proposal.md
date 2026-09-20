## Why

Ya existe un widget de Spotify en `.config/eww/player/player.yuck` — con carátula, barra de progreso, shuffle/loop y controles — pero **está muerto**: todos sus `defpoll` invocan `playerctl`, que no está instalado en el sistema. Además no tiene ningún atajo que lo abra, está anclado abajo al centro en lugar de bajo la barra, y arrastra varios bugs de cableado (variables cruzadas, progreso que siempre marca el final).

En paralelo, tres de las cuatro teclas multimedia están rotas por una ruta mal escrita en `sxhkdrc`: apuntan a `~/.config/sxhkd/spotify_control` en lugar de `~/.config/sxhkd/scripts/spotify_control`, que es donde el script sí existe.

El objetivo es poder ver y controlar Spotify desde un panel flotante bajo la barra, sin darle foco a la ventana de Spotify.

## What Changes

- **Instalar `playerctl`**, la única causa de que el widget existente no muestre nada.
- **Reubicar la ventana `music`** de `:anchor "bottom center"` con `:y "-7%"` a `:anchor "top right"` con `:y "46px"`, de modo que cuelgue justo bajo `bar/main` de Polybar (42px de alto más 4px de aire).
- **Corregir los bugs de cableado del widget existente**:
  - Los `defpoll` `shuffle` y `loop` están **cruzados**: `shuffle` ejecuta `playerctl loop` y `loop` ejecuta `playerctl shuffle`.
  - `music-positions`, `music-length` y `music-lengths` consultan los tres lo mismo (`mpris:length`), así que la barra de progreso usa la duración como posición y aparece siempre llena.
  - `music-position` viene en segundos y `music-length` en microsegundos: los tiempos se muestran en unidades distintas y sin formato `m:ss`.
- **Añadir estado "sin reproductor"**: hoy, con Spotify cerrado, los `defpoll` fallan y el panel muestra campos vacíos o datos obsoletos.
- **Añadir atajo de apertura** (`super + ctrl + s`) con un script de toggle equivalente a `show_wifi_widget.sh`, con guarda `timeout`, `-c` explícito y selección explícita de output.
- **Unificar el control sobre `playerctl`**: el script `spotify_control` existente (basado en `dbus-send`) gana los subcomandos que hoy no tiene (`seek-forward`, `seek-backward`, `shuffle`, `repeat`) y pasa a ser la única vía de control, usada tanto por las teclas como por los botones del widget.
- **Reparar las rutas rotas** de `XF86AudioStop`, `XF86AudioPrev` y `XF86AudioNext` en `sxhkdrc`, y migrar los `super + F10/F11/Pause/Delete` de `dbus-send` crudo al script unificado.
- **Retirar los módulos MPD muertos** de Polybar (`[module/mpd]`, `[module/mpd_control]`), que apuntan a un daemon MPD que no corre y a un comando `OpenApps` inexistente.

Fuera de alcance: carátula del álbum (hoy no carga y se aborda aparte), control de volumen, y generalizar el rice a multi-monitor. Ver `design.md`.

## Capabilities

### New Capabilities

- `spotify-control`: capa de control de reproducción sobre MPRIS que expone comandos (play/pause, next, previous, stop, seek, shuffle, repeat) y lectura de estado y metadata, consumible tanto por atajos de teclado como por el widget. Define el comportamiento cuando Spotify no está corriendo.
- `spotify-widget`: panel flotante en EWW que presenta el estado de reproducción y expone los controles, incluyendo su geometría de anclaje bajo la barra, la selección de monitor y la semántica de apertura por atajo.

### Modified Capabilities

Ninguna — `openspec/specs/` está vacío, este es el primer change del repo.

## Impact

**Archivos modificados:**
- `.config/eww/player/player.yuck`: geometría de la ventana, corrección de los `defpoll` cruzados y de posición/duración, estado sin reproductor, delegación de los botones en `spotify_control`
- `.config/sxhkd/scripts/spotify_control`: reescrito sobre `playerctl`, con los subcomandos nuevos
- `.config/sxhkd/sxhkdrc`: rutas corregidas, atajos migrados, nuevo atajo de toggle
- `README.md`: documentar el widget, su atajo, la dependencia y el acoplamiento del offset con la altura de la barra

**Archivos nuevos:**
- `.config/bspwm/scripts/player/show_player_widget.sh`: script de toggle, en línea con `show_wifi_widget.sh`
- `.config/bspwm/scripts/player/get_player_state.sh`: lectura de estado y metadata para los `defpoll`

**Fuera del repo (edición manual):**
- `~/.config/polybar/modules.ini` y `config.ini`: retirar los módulos MPD. **`~/.config/polybar/` no está versionado en este repositorio.**

**Dependencias:**
- Nueva: `playerctl` (2.4.1-4, disponible en apt)
- Existentes: `eww` 0.6.0, `sxhkd`, `bspwm`, cliente oficial `spotify`

**Riesgos:**
- Editar el repo no afecta la sesión viva: `~/.config/` son copias independientes, no symlinks. Cada verificación exige sincronizar antes.
- Corren **dos daemons de eww** (el de `~/.config/eww` y el del proyecto `display-manager`), así que toda invocación debe pasar `-c` explícito para no hablarle al daemon equivocado.
- El offset de 46px depende de `height = 42` en un archivo fuera del repo; si cambia, hay que ajustarlo a mano.
