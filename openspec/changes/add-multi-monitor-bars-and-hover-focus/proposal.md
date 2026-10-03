## Why

El usuario trabaja en un laptop (`eDP`, primary) y conecta con frecuencia un monitor externo (`HDMI-A-0`, a la derecha), pero el rice solo vive en el primary: las 6 barras de polybar heredan de `bar/main` con `monitor =` vacío y caen todas en `eDP`, y `set_workspaces` nombra escritorios solo en el monitor enfocado, así que el externo queda con un único escritorio `Desktop` y sin barra. Eso le obliga a "voltear" la cabeza hacia el laptop para ver escritorios, hora, batería o Spotify. Además, tras probar el click-to-focus introducido en `refine-mac-like-window-transitions`, quiere recuperar el foco por hover (`focus_follows_pointer`), que encaja mejor con un flujo de dos pantallas: al cruzar al otro monitor el foco le sigue sin click.

## What Changes

- **BREAKING (spec)**: volver a `bspc config focus_follows_pointer true` en `bspwmrc`. Se reemplaza el requisito "Foco por click, no por hover" del spec `desktop-window-transitions` por uno de foco por hover (el click sigue enfocando).
- Lanzar **una instancia de cada una de las 6 barras** de polybar (`workspace.ini`: `primary`; `current.ini`: `updates`, `date`, `target_to_hack`, `primary`, `principal_bar`) **en cada monitor conectado**, en lugar de una sola en el primary. `bar/main` en ambos `.ini` pasa a tomar el monitor de una variable de entorno y `launch.sh` itera sobre los monitores conectados.
- Escritorios por monitor con reparto fijo: `eDP` → `I II III IV V VI`; monitor externo → `VII VIII IX X`. `set_workspaces` pasa a recibir el monitor objetivo y se corrige su fallback (que hoy define `VII` dos veces y omite `V`). Los atajos existentes `super+{1-9,0}` (índice global `^N`) llegan así al externo sin cambios en `sxhkdrc`.
- **Hotplug automático**: un listener nuevo, lanzado desde `bspwmrc`, reacciona a la conexión, desconexión y cambio de geometría de monitores; al conectar asigna (o recupera, con sus ventanas) los escritorios `VII..X` al externo, y en cualquier evento relanza polybar y los widgets eww por pantalla.
- `bspc config remove_unplugged_monitors true`, para que al desenchufar el externo sus escritorios y ventanas se fusionen en `eDP` en vez de quedar en un monitor fantasma inaccesible.
- **Spotify en ambas pantallas**: un `player-trigger` de eww por monitor (instancias con id y pantalla propios) y un único `player-panel` que se abre en la pantalla del trigger sobre el que está el puntero. `hover_player.sh` pasa a recibir el monitor.
- Sincronizar el repo desde `~/.config` (fuente de verdad viva) para los archivos que toca este change: `bspwmrc` (hoy divergido), la config de polybar (`launch.sh`, `current.ini`, `workspace.ini` y sus includes de colores) y el widget de Spotify (`eww/player/`, `bspwm/scripts/player/`), que no están versionados.

## Capabilities

### New Capabilities
- `multi-monitor-desktop`: presencia del rice en todos los monitores conectados — barras de polybar por monitor, reparto de escritorios entre `eDP` y el externo, reacción automática a conexión/desconexión, y el trigger de Spotify en cada barra.

### Modified Capabilities
- `desktop-window-transitions`: el requisito "Foco por click, no por hover" se sustituye por foco que sigue al puntero (hover), manteniendo que un click también enfoca.

## Impact

- **Archivos vivos** (`~/.config`, fuente de verdad): `bspwm/bspwmrc`, `polybar/launch.sh`, `polybar/current.ini`, `polybar/workspace.ini`, `eww/player/player.yuck`, `bspwm/scripts/player/hover_player.sh`, más un script nuevo de listener de monitores en `bspwm/scripts/`.
- **Repo**: se añaden/actualizan sus copias bajo `.config/` (polybar y player entran por primera vez al repo); README si documenta el arranque.
- **Dependencias**: ninguna nueva (`bspc`, `polybar 3.7.2`, `eww 0.6.0`, `xrandr`, `xdotool`, `xwininfo` ya presentes). Hay un supuesto a validar con un spike: que `eww open --screen` acepte el nombre del monitor en X11.
- **Sin cambios**: picom, sxhkd, touchpad, widgets eww de volumen/brillo/wifi (siguen abriendo en el primary). Las ventanas flotantes con offsets fijos que lanzan algunos módulos de la barra (`kitty.window.float`) no se adaptan por monitor en este change.
- **Aplicación**: `bspc wm -r` recarga bspwmrc, el listener y polybar; no hace falta reiniciar la sesión X.
