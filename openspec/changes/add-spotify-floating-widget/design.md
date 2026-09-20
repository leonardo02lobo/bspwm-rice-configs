## Context

El punto de partida real no es un hueco vacío, sino un widget completo que no arranca.

`.config/eww/player/player.yuck` define una ventana `music` con carátula, título, artista, barra de progreso, shuffle, loop, controles de pista y un botón de cierre. Once `defpoll` a 1s alimentan el widget, todos vía `playerctl` — **que no está instalado**. Con cada poll fallando, el panel renderiza vacío. Tampoco hay ningún atajo en `sxhkdrc` que lo abra, así que en la práctica nunca se ve.

`.config/sxhkd/scripts/spotify_control` sí existe y funciona: es un `case` sobre `dbus-send` con `playpause`, `next`, `previous`, `stop`, `play` y `looptrack`. Solo `XF86AudioPlay` lo invoca por su ruta correcta; `Stop`, `Prev` y `Next` apuntan a `~/.config/sxhkd/spotify_control`, sin el `scripts/`, y por eso no hacen nada. Los atajos `super + F10/F11/Pause/Delete` hablan `dbus-send` directo, sin pasar por el script.

Dos restricciones del entorno que condicionan el diseño:

- **`~/.config/` no son symlinks al repo**, son copias independientes que hoy coinciden. Editar el repo no cambia la sesión viva; verificar exige copiar primero.
- **Corren dos daemons de eww**: el de `~/.config/eww` y otro que `bspwmrc` lanza con `--config ~/Documentos/Project/display-manager/widget/eww`. Un `eww open` sin `-c` puede acabar en el daemon equivocado. `show_wifi_widget.sh` ya pasa `-c` explícito; es el precedente a seguir.

La barra superior es Polybar `bar/main` (`bottom = false`, `height = 42`, `monitor = "eDP"`, `monitor-fallback = "HDMI-2"`), definida en `~/.config/polybar/` — fuera de este repositorio. Polybar no itera sobre los outputs conectados: renderiza una sola barra, en `eDP` o en `HDMI-2`, nunca en ambos.

## Goals / Non-Goals

**Goals:**

- Dejar operativo el widget que ya existe, con el mínimo de cambios sobre su estructura.
- Reubicarlo bajo la barra, que es la petición original.
- Un único camino de control compartido entre widget y teclado.
- Comportamiento predecible con Spotify cerrado.

**Non-Goals:**

- **Reescribir el widget desde cero.** Su estructura y estilos funcionan; el trabajo es de cableado y ubicación.
- **Generalizar el rice a multi-monitor.** El widget se pinea al output donde Polybar ya renderiza.
- **Carátula del álbum.** Ver decisión 6.
- **Control de volumen.** Ver decisión 7.
- **Funciones de la Web API** (Spotify Connect, "me gusta", playlists): MPRIS no las expone.
- **Sustituir los módulos MPD por un módulo nativo de Polybar.** Se retiran por muertos; el estado en vivo vive en el panel.

## Decisions

### 1. Instalar `playerctl` en lugar de reescribir el widget sobre `dbus-send`

**Por qué:** el widget ya está escrito contra `playerctl` en sus once `defpoll`. Migrarlo a `dbus-send` significaría reescribir cada uno con parseo de salida verbosa, frágil ante títulos con comillas. Instalar un paquete de los repos oficiales es incomparablemente más barato que reescribir el widget entero.

**Alternativa considerada:** mantener cero dependencias nuevas migrando todo a `dbus-send`. Se descarta por la asimetría de esfuerzo.

### 2. Unificar `spotify_control` sobre `playerctl`

Una vez `playerctl` es dependencia dura del widget, el script deja de usar `dbus-send` y pasa a ser la única vía de control, con los subcomandos que hoy le faltan (`seek-forward`, `seek-backward`, `shuffle`, `repeat`).

**Por qué:** si el widget llama a `playerctl` directo en sus `:onclick` y las teclas llaman a un script `dbus-send`, hay dos implementaciones del mismo control divergiendo. Centralizar deja un solo lugar donde arreglar cosas.

**Consecuencia:** los botones del widget dejan de invocar `playerctl` directamente y pasan por el script, y los `super + F10/F11/Pause/Delete` se migran también.

### 3. Corregir el cableado, no rediseñar la interfaz

Tres bugs concretos, todos de variables mal enchufadas:

- `shuffle` y `loop` están cruzados: el `defpoll` llamado `shuffle` ejecuta `playerctl loop`, y el llamado `loop` ejecuta `playerctl shuffle`. Los botones muestran y alternan el estado contrario al que dicen.
- `music-positions`, `music-length` y `music-lengths` consultan los tres `mpris:length`. La escala usa `:value music-positions`, es decir la duración, así que la barra aparece siempre al 100%.
- `music-position` viene en segundos (float) y `music-length` en microsegundos: los dos números del contador no son comparables y ninguno está formateado como `m:ss`.

**Por qué corregirlos aquí:** reubicar un widget que muestra información falsa no resuelve el problema del usuario, y son correcciones de pocas líneas sobre código que ya existe.

### 4. Anclaje `top right` con offset fijo de 46px

`:anchor "top right"`, `:y "46px"` (42px de `bar/main` + 4px de aire), sustituyendo el `:y "-7%"` / `bottom center` actual.

**Por qué píxeles y no porcentaje:** la barra mide 42px absolutos independientemente de la resolución del output, así que el offset correcto también es absoluto. El `-7%` actual se desalinea al cambiar de resolución.

**Acoplamiento aceptado:** el 46px depende de un valor en un archivo fuera del repo. Leer el `.ini` de Polybar en arranque añadiría fragilidad por un beneficio marginal; se documenta en el README.

### 5. Monitor explícito, no el `primary` de X

La ventana se abre indicando el output explícitamente, replicando la lógica de Polybar: `eDP`, y `HDMI-2` si `eDP` no está conectado.

**Por qué:** Polybar fija su barra por nombre de salida, no por `primary`. Si al conectar un externo ese externo queda marcado como `primary`, EWW abriría el panel ahí mientras la barra sigue en `eDP`: el panel flotaría bajo una barra inexistente. No hay `.xprofile`, `.xinitrc` ni `autorandr` que gestione qué output es `primary`, así que no se puede asumir.

**Dónde vive la decisión:** en el script de toggle, vía `--screen`, no en el `.yuck`. El script puede consultar los outputs conectados y aplicar el fallback; el `.yuck` es estático.

### 6. La carátula queda fuera de alcance, pero se deja degradando limpio

Hoy `.player-art` recibe `background-image: url('${music-art}')` con la URL remota `https://` de `mpris:artUrl`. GTK no carga URLs remotas en CSS, así que nunca se ve.

**Por qué no arreglarlo ahora:** exige descargar y cachear en disco por pista, con invalidación, que es un mecanismo nuevo y no es lo que se pidió. Se deja el contenedor con su color de fondo, que es exactamente lo que se ve hoy, y se aborda en una iteración aparte.

### 7. Sin control de volumen

El cliente Linux de Spotify no implementa de forma fiable el setter `Volume` de MPRIS. La alternativa real es el sink-input de PulseAudio con `pactl`, que es un mecanismo distinto (aplicación vs reproductor). Un control que a veces no responde es peor que no ofrecerlo.

### 8. `repeat` cicla desde el widget, con estado explícito desde el teclado

Sin argumento, `repeat` cicla `None → Playlist → Track → None`, que es lo que necesita un botón único. Con argumento (`repeat Playlist`), fija ese estado.

**Por qué:** `super + Pause` y `super + Delete` hoy fijan `Playlist` y `Track`. Migrarlos sin perder su semántica exige el modo explícito; el panel necesita el cíclico. Un solo subcomando cubre ambos.

### 9. Polling, no el modelo push del OSD de volumen

El OSD de volumen migró recientemente de `defpoll` a `defvar` + `eww update` empujado desde los scripts de teclado.

**Por qué no replicarlo aquí:** ese modelo funciona porque todo cambio de volumen nace de una pulsación. El estado de Spotify cambia solo (la pista termina, o la cambias desde la ventana de Spotify), así que hace falta consultar. Se mantiene el `:interval "1s"` que el widget ya usa.

### 10. Un solo `defpoll` con JSON, no uno por campo

El widget pasa de once `defpoll` a uno solo, que invoca un script que emite un JSON de una línea con todos los campos; el `.yuck` accede a ellos como `player.title`, `player.status`, etc.

**Por qué:** los `defpoll` corren aunque la ventana esté cerrada. Nueve o diez invocaciones por segundo, cada una levantando un proceso `playerctl`, es coste permanente en un laptop; una sola lo reduce en un orden de magnitud. El JSON se construye con `jq`, ya presente en el sistema, para que un título con comillas no rompa la salida.

**Alternativa considerada:** un script parametrizado por campo, un valor por invocación. Más simple de leer, pero paga el coste en cada tick para siempre.

### 11. Valor centinela `Offline` para el estado sin Spotify

Los scripts de lectura salen con código cero siempre, devolviendo `Offline` para el estado y cadena vacía para la metadata.

**Por qué:** un `defpoll` cuyo script falla deja la variable en su valor anterior, así que el panel mostraría metadata de una sesión ya cerrada. Con un centinela explícito, el `.yuck` puede ramificar y mostrar "sin reproductor activo".

### 12. La ventana sigue llamándose `music`

**Por qué:** el nombre ya está referenciado desde el propio botón de cierre del widget. Renombrarla a `player` es churn sin beneficio.

## Risks / Trade-offs

- **El repo y la sesión viva son copias independientes** → cada verificación exige copiar del repo a `~/.config/` primero; se hace explícito en las tareas y no se da por hecho.
- **Dos daemons de eww corriendo** → todas las invocaciones nuevas pasan `-c ~/.config/eww` explícito, como ya hace `show_wifi_widget.sh`.
- **Migrar `super + F10/F11/Pause/Delete` toca atajos que hoy sí funcionan** → se verifica cada uno manualmente tras la migración; el `dbus-send` original queda en el historial de git.
- **`super + ctrl + s` podría chocar con algún atajo** → verificado contra `sxhkdrc`: los `super + ctrl` ocupados son `w`, `m/x/y/z`, `h/j/k/l`, `1-9`, `space`, `shift + space` y las flechas. `s` está libre.
- **La limpieza de Polybar no queda versionada** → se documenta en el README como paso manual; se limita a borrar dos módulos que hoy no están activos en ninguna `modules-*`.
- **`playerctl` depende de que el reproductor se llame `spotify`** → se centraliza el nombre en una variable del script.

## Migration Plan

1. Instalar `playerctl`: sin él nada de lo demás se puede verificar.
2. Corregir el script de control y las rutas de `sxhkdrc`, y verificar las teclas multimedia — es la parte que da valor inmediato y no depende del widget.
3. Corregir el cableado del widget y reubicarlo.
4. Añadir el script de toggle y su atajo.
5. Retirar los módulos MPD de Polybar al final, por ser el único paso fuera del repo.

**Rollback:** todo vive en archivos versionados salvo el paso 5; revertir el commit restaura el estado anterior.

## Open Questions

- ¿El offset de 46px se ve bien, o el panel necesita más aire? Se ajusta al verlo.
- ¿Conviene que el panel se cierre al perder el foco? El de WiFi no lo hace; se mantiene el mismo comportamiento salvo que moleste.
- La carátula y el volumen por `pactl` quedan como candidatos a una segunda iteración.
