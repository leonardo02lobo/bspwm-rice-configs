## Context

El rice está pensado para una sola pantalla, aunque el usuario conecta a menudo un monitor externo. Estado actual (observado con `HDMI-A-0` conectado en `+1920+0`, `eDP` como primary):

```
eDP (primary)                              HDMI-A-0
┌──────────────────────────────────┐       ┌──────────────────────────────┐
│ [principal_bar ············ ][≡] │       │                              │
│   [workspaces I..VI]   ♪ (eww)   │       │   sin barra                  │
│ [updates] [date] [target]        │       │   escritorios: "Desktop"     │
└──────────────────────────────────┘       └──────────────────────────────┘
```

- **Polybar** no es una barra sino 6 "islas" flotantes: `workspace.ini` → `bar/primary` (módulo `xworkspaces`, `pin-workspaces = true`, `override-redirect`); `current.ini` → `updates`, `date`, `target_to_hack`, `primary` (sysmenu), `principal_bar` (IPC). Todas heredan de `bar/main`, que en ambos archivos tiene `monitor =` vacío, así que polybar las pone en el primary. `launch.sh` las mata y relanza en serie.
- **Escritorios**: `set_workspaces 6` ejecuta `bspc monitor -d I..VI`, que solo afecta al monitor enfocado. Su fallback define `I II III IV VI VII VII VIII IX X` (`VII` duplicado y sin `V`).
- **sxhkd**: `super+{1-9,0}` → `bspc desktop -f '^{1-9,10}'`, por índice global, no por nombre.
- **bspwm**: `remove_unplugged_monitors`, `remove_disabled_monitors` y `merge_overlapping_monitors` están en `false`. `focus_follows_pointer false`, desde el change archivado `refine-mac-like-window-transitions`.
- **Spotify**: `player-trigger` (eww, `wm-ignore`, `focusable false`, anclado `top right`, `x -690px`, medido sobre el hueco de `principal_bar`) se abre desde `bspwmrc` cuando el daemon responde a `ping`. `hover_player.sh show|hide` abre o cierra un único `player-panel`. Guarda el estado en un solo fichero (`/tmp/.eww_player_hover.state`), usa una `defvar player-hover` global, y para decidir los falsos `hide` busca los rectángulos de las ventanas `"Eww - player-(trigger|panel)"` en `xwininfo`.
- **Hotplug**: no hay `autorandr`, `.xprofile` ni udev rules. El usuario activa y desactiva el externo a mano con xrandr (normalmente `--off`, lo que bspwm trata como monitor *disabled*, no *unplugged*).
- **Repo y config viva**: `~/.config` es la fuente de verdad. El `bspwmrc` del repo está desactualizado (le falta el arranque de los daemons eww y el player-trigger, y tiene otro wallpaper). Polybar, `eww/player/` y `bspwm/scripts/player/` no están versionados, aunque `eww.yuck` del repo ya incluye `player/player.yuck`.
- Versiones: polybar 3.7.2, eww 0.6.0, monitores de 1920x1080.

## Goals / Non-Goals

**Goals:**
- Las 6 barras en cada monitor activo, con la misma disposición.
- Escritorios `I..VI` en `eDP` y `VII..X` en el externo, sin `Desktop` por defecto.
- Conectar, desconectar o cambiar la geometría reconfigura todo sin intervención, y ninguna ventana queda inaccesible.
- Trigger de Spotify en cada barra, con el panel desplegándose en la pantalla del trigger.
- Foco por hover.
- Repo sincronizado con la config viva para todos los archivos que toca el change.

**Non-Goals:**
- Más de un monitor externo a la vez. Un segundo externo recibe barras, pero el reparto de escritorios solo contempla uno (ver Open Questions).
- Gestionar resolución y primary con xrandr: siguen siendo manuales, y no se introduce autorandr. La **posición** del externo sí se gestiona (decisión 8).
- Adaptar por monitor los widgets eww de volumen, brillo, wifi, calendario y cheatsheet, ni las ventanas `kitty.window.float` con offsets fijos que lanzan algunos módulos de la barra. Siguen apareciendo donde aparecen hoy.
- Tocar picom, sxhkd o el touchpad.

## Decisions

### 1. Monitor de cada barra vía variable de entorno, no barras duplicadas por monitor en el `.ini`

`bar/main` en `current.ini` y `workspace.ini` pasa a `monitor = ${env:MONITOR:}`, y `launch.sh` itera sobre `polybar --list-monitors` lanzando cada barra con `MONITOR=<nombre>`. Como todas heredan de `bar/main`, se cambia una sola línea por archivo. Si `MONITOR` está vacío se conserva el comportamiento actual (primary).

*Alternativa descartada*: secciones `bar/principal_bar-hdmi`, etc. Duplica 6 bloques por monitor y acopla los `.ini` a nombres de output concretos.

*Por qué `--list-monitors`*: devuelve exactamente los outputs que polybar sabe usar, así que evita lanzar barras en outputs conectados pero apagados (`xrandr --query | grep connected` sí lo haría).

### 2. Una única función de reconciliación de escritorios, idempotente, para el arranque y el hotplug

Un script nuevo, `~/.config/bspwm/scripts/monitors/setup_monitors.sh`, contiene la lógica de "dejar el estado como debe estar". Lo llaman tanto `bspwmrc` como el listener:

```
para el monitor laptop (nombre ^eDP):     asegurar I..VI
para el (primer) monitor externo:
    para cada d en VII..X:
        si d existe en algún monitor  → bspc desktop d -m <externo>   (se lleva sus ventanas)
        si no                         → bspc monitor <externo> -a d
    eliminar el escritorio por defecto "Desktop" del externo si sigue ahí
    reordenar con bspc monitor <externo> -o VII VIII IX X
relanzar polybar (launch.sh)
reabrir los player-trigger por monitor
```

- **No se usa `bspc monitor -d` sobre monitores que ya tienen escritorios**, porque `-d` reasigna o elimina escritorios existentes. En un `bspc wm -r` con ventanas abiertas, eso no es inocuo. `-a`/`-m`/`-o` sí son seguros al repetirlos. `set_workspaces` se reescribe como `set_workspaces <monitor> <desde> <hasta>`, que añade solo los escritorios que faltan, y su fallback queda corregido.
- **Laptop por nombre (`^eDP`) y no por `primary`**: la memoria del proyecto y el Context muestran que el primary depende del xrandr manual y no se puede asumir. El panel interno sí es estable.
- **Orden global `^N`**: bspwm numera los escritorios por orden de monitor. `eDP` debe ir antes que el externo, y como el externo se añade después, esa es la situación natural. Se verifica en las tareas, y si hiciera falta, se reordena con `bspc wm -O`.

*Alternativa descartada*: lógica distinta en `bspwmrc` y en el listener. Divergiría, igual que ya ha pasado entre el repo y la config viva.

### 3. Listener de hotplug con `bspc subscribe`, de instancia única y con debounce

Un segundo script, `monitor_hotplug.sh`, ejecuta `bspc subscribe monitor_add monitor_remove monitor_geometry` y, ante cada evento, llama a `setup_monitors.sh`.

- **Instancia única**: `bspc wm -r` vuelve a ejecutar `bspwmrc`, así que al arrancar el listener mata la instancia anterior (pidfile en `$XDG_RUNTIME_DIR`). Sin esto, cada recarga acumularía un listener más y polybar se relanzaría N veces.
- **Debounce (~0.5 s)**: un `xrandr` dispara ráfagas de eventos (add + geometry, o varios geometry). Solo se reconcilia cuando la ráfaga termina.
- **Por qué `bspc subscribe` y no udev/`xrandr --listen`**: bspwm ya traduce los cambios de RandR a eventos de monitor. Además, cuando llega `monitor_add`, bspwm ya ha creado el monitor, así que se le pueden asignar escritorios sin carreras. Udev avisa del cable, no de la activación con xrandr, que es lo que el usuario hace realmente.

### 4. `remove_unplugged_monitors true` **y** `remove_disabled_monitors true`

El usuario apaga el externo con `xrandr --off`, que bspwm trata como monitor disabled. Si solo se activara `remove_unplugged_monitors`, el caso habitual dejaría un monitor fantasma con ventanas inaccesibles. Al eliminar un monitor, bspwm fusiona sus escritorios (con ventanas) en otro, y con un solo monitor restante el destino es `eDP`. En la reconexión, la decisión 2 los devuelve al externo moviéndolos por nombre.

### 5. Spotify: un trigger por pantalla, un solo panel que sigue al trigger

```
  eDP bar:   … [♪ trigger:eDP] …          HDMI bar:  … [♪ trigger:HDMI-A-0] …
                     │ hover                                  │ hover
                     └──────────► hover_player.sh show <mon> ◄┘
                                         │
                       panel abierto en otro monitor? → cerrar
                       eww open player-panel --screen <mon>
```

- `player-trigger` se abre una vez por monitor: `eww open player-trigger --id player-trigger-<mon> --screen <mon> --arg monitor=<mon>`. La ventana declara el argumento `monitor` y el widget lo reenvía en `:onhover "${hover} show ${monitor}"` (y en el `hide`).
- **Un solo `player-panel`**, porque solo puede estar desplegado bajo el trigger que tiene el puntero. Así siguen valiendo la `defvar player-hover` global y el fichero de estado. Ese fichero pasa a guardar el monitor del panel abierto. Si llega `show <otro-monitor>`, el script cierra el panel y lo reabre en la pantalla nueva.
- El mismo offset `x -690px` sirve en ambos monitores, porque las barras son idénticas (mismos `%` sobre 1920 px).
- `pointer_over_player` sigue funcionando: busca por regex `player-(trigger|panel)` entre todas las ventanas, así que cubre los triggers de todas las pantallas. Hay que confirmar en el spike que el título X con `--id` sigue empezando por `Eww - player-trigger`.
- La apertura de los triggers sale de `bspwmrc` y pasa a `setup_monitors.sh`, que primero cierra todos los `player-trigger-*` activos (`eww active-windows`) y luego abre uno por monitor. Así no quedan triggers huérfanos de un monitor desconectado.

*Alternativa descartada*: un panel por monitor con una variable de revelado por instancia. eww 0.6 no tiene variables por instancia de ventana, así que habría que duplicar estado y fichero de lock por monitor, a cambio de nada, porque el puntero solo puede estar en un trigger a la vez.

### 6. Foco por hover: una línea, más el delta de spec

`bspc config focus_follows_pointer true`. Las barras y los widgets eww no los gestiona bspwm (`override-redirect`/`wm-ignore`), así que el hover sobre ellos no mueve el foco. picom tiene `inactive-opacity = 1.0`, así que el cambio de foco no produce parpadeos. El spec `desktop-window-transitions` sustituye su requisito de click-to-focus.

### 7. Sincronización repo ← config viva en dos pasos

1. **Baseline**: antes de tocar nada, copiar al repo el estado vivo actual de los archivos afectados (`bspwmrc`, `polybar/{launch.sh,current.ini,workspace.ini,colors.ini,catppuccin-colors.ini}`, `eww/player/*`, `bspwm/scripts/player/*`). Esto se commitea aparte, para que el diff del change muestre solo el cambio y no la deriva acumulada.
2. **Implementar en `~/.config`** (es lo que se prueba en vivo) y, al terminar, volver a copiar al repo junto con los scripts nuevos de `bspwm/scripts/monitors/`.

Antes del baseline se revisa que los archivos copiados no contengan secretos ni rutas personales sensibles. Se excluyen los `.backup` y las variantes de polybar no usadas (`config`, `config.ini`, `data.ini`, `modules.ini`, `colors_dark/light.ini`).

### 8. El externo siempre a la derecha de `eDP`, corregido en la reconciliación

*Añadida durante la implementación (2026-10-03).* Al probar el hotplug, xrandr dejó el externo en la posición que indicaba el último comando, y el usuario quiere llegar a él moviendo el ratón hacia la derecha. Sin `.xprofile` ni autorandr, nada recordaba la posición entre conexiones. `setup_monitors.sh` incorpora `place_external`, que se ejecuta antes de repartir los escritorios:

- Compara los rectángulos de bspwm. Si el borde izquierdo del externo no coincide con el borde derecho de `eDP`, ejecuta `xrandr --output <externo> --right-of <laptop>` y espera (con tope de 2 s) a que bspwm refleje la nueva geometría antes de lanzar las barras.
- **Guard anti-bucle**: el xrandr dispara un `monitor_geometry`, y el listener vuelve a reconciliar. En esa segunda pasada la posición ya cuadra, así que no se llama a xrandr y la cadena termina. El coste es un relanzamiento extra de polybar al corregir la posición, y solo entonces.

*Alternativa descartada*: un `.xprofile` con el xrandr. Solo actúa al iniciar la sesión, no al reconectar el cable o reactivar el externo con `--auto`, que es justo cuando X lo coloca mal.

## Risks / Trade-offs

- **[eww 0.6 `--screen` podría no aceptar el nombre del output en X11]** → **Resuelto en el spike (2026-10-03)**: `--screen HDMI-A-0` y `--screen 1` colocan la ventana en el mismo sitio (x 3121 = 1920 + 1201). Un nombre inválido falla con rc=1 y lista los monitores disponibles, sin abrir nada. Se usa el **nombre**. El título X sigue siendo `Eww - player-trigger` con cualquier `--id`, así que `pointer_over_player` no cambia.
- **[El hover roba el foco del popup wifi (`focusable true`) si el puntero cruza otra ventana camino al popup]** → Se acepta. Se documenta, y si molesta, se arregla en otro change (por ejemplo, cerrar el popup al perder el foco).
- **[Relanzar polybar entero en cada evento produce un parpadeo de las 12 barras]** → Se acepta. Los eventos son poco frecuentes (conectar o desconectar), y el debounce evita relanzamientos en cascada.
- **[`bspc wm -r` con el listener activo]** → El pidfile garantiza una sola instancia, y la reconciliación es idempotente, así que repetirla no destruye escritorios ni mueve ventanas.
- **[El orden global de escritorios podría quedar con el externo antes de `eDP`]** (si bspwm inserta el monitor nuevo antes) → Se verifica en las tareas y, si pasa, se corrige con `bspc wm -O eDP <externo>` dentro de la reconciliación.
- **[`polybar-msg` llega a todas las instancias]** → Es el comportamiento deseado: los hooks IPC de `principal_bar` deben actualizar ambas barras.
- **[Ventanas flotantes con offsets fijos que se lanzan desde la barra (sysfetch, checkupdates)]** → Fuera de alcance. Pueden aparecer en la pantalla "equivocada" al hacer click desde la barra del externo.

## Migration Plan

1. Baseline del repo (decisión 7, paso 1) y commit.
2. Spike de `eww --screen`.
3. Aplicar los cambios en `~/.config` y recargar con `bspc wm -r`. Probar sin externo, conectar `HDMI-A-0` con xrandr, mover ventanas a `VII..X`, apagar con `--off`, volver a encender, y comprobar el hover de Spotify en ambas pantallas.
4. Copiar al repo y commitear.

**Rollback**: restaurar los archivos vivos desde el commit baseline del repo y ejecutar `bspc wm -r`. Matar el listener (`pkill -f monitor_hotplug.sh`) si sigue vivo.

## Open Questions

- Si algún día hay dos externos a la vez: ¿`XI..XVI` para el segundo (los atajos `^11–16` ya existen en `sxhkdrc`)? Queda fuera de este change.
