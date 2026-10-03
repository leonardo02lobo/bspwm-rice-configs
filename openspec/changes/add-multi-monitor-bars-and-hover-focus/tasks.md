## 1. Baseline del repo y spike

- [x] 1.1 Revisar que los archivos vivos a versionar no contengan secretos ni datos sensibles: `~/.config/bspwm/bspwmrc`, `~/.config/polybar/{launch.sh,current.ini,workspace.ini,colors.ini,catppuccin-colors.ini}`, `~/.config/eww/player/*`, `~/.config/bspwm/scripts/player/*`
- [x] 1.2 Copiar esos archivos tal cual al repo bajo `.config/` (sin `.backup` ni variantes de polybar no usadas) y commitear como baseline separado ("sync live config"), antes de cualquier cambio funcional
- [x] 1.3 Spike: con `HDMI-A-0` activo, probar `eww open player-trigger --id t-test --screen HDMI-A-0` y `--screen 1`. Anotar si `--screen` acepta el nombre del output, qué título X recibe la ventana (`xwininfo -root -tree | grep Eww`) y si `pointer_over_player` sigue encontrándola. Cerrar la instancia de prueba
- [x] 1.4 Registrar el resultado del spike en `design.md` (decisión 5 y riesgo de `--screen`) y elegir nombre o índice para el resto de tareas

## 2. Foco por hover

- [x] 2.1 En `~/.config/bspwm/bspwmrc`, cambiar `bspc config focus_follows_pointer false` a `true`
- [x] 2.2 Tras `bspc wm -r`, verificar que el hover sobre una ventana la enfoca, que pasar sobre polybar o un widget eww no cambia el foco, y que el click sigue enfocando

## 3. Polybar por monitor

- [x] 3.1 En `bar/main` de `~/.config/polybar/current.ini` y `~/.config/polybar/workspace.ini`, poner `monitor = ${env:MONITOR:}`
- [x] 3.2 Reescribir `~/.config/polybar/launch.sh` para que, tras matar las barras, itere sobre `polybar --list-monitors` y lance las 6 barras (`workspace.ini` primary; `current.ini` updates, date, target_to_hack, primary, principal_bar) con `MONITOR=<nombre>` para cada monitor, conservando `trap '' HUP` y `disown`
- [x] 3.3 Verificar con solo `eDP` que hay exactamente 6 procesos polybar en las mismas posiciones que antes, y con `HDMI-A-0` activo que hay 12 con la misma disposición en ambos monitores

## 4. Escritorios y reconciliación

- [x] 4.1 Crear `~/.config/bspwm/scripts/monitors/setup_monitors.sh` con un `set_workspaces <monitor> <desde> <hasta>` idempotente (números romanos vía perl Roman, añade solo los que faltan y nunca usa `bspc monitor -d` sobre un monitor con escritorios) y con su fallback corregido (nombres únicos y consecutivos)
- [x] 4.2 En `setup_monitors.sh`, detectar el monitor laptop por nombre (`^eDP`) y asegurar `I..VI` en él
- [x] 4.3 En `setup_monitors.sh`, para el primer monitor externo activo: mover `VII..X` si ya existen en otro monitor (`bspc desktop <d> -m <externo>`), añadir los que falten, eliminar su `Desktop` por defecto y ordenar con `bspc monitor <externo> -o VII VIII IX X`
- [x] 4.4 Asegurar el orden global de monitores con `eDP` primero (`bspc wm -O` si hace falta) y comprobar que `super+7` enfoca `VII` en el externo
- [x] 4.5 Al final de `setup_monitors.sh`, relanzar polybar (`launch.sh`) y los triggers de Spotify (ver 6.4)
- [x] 4.6 En `bspwmrc`: quitar `set_workspaces 6`, la llamada directa a `launch.sh` y el bloque que abre `player-trigger`, y sustituirlos por una llamada a `setup_monitors.sh` cuando el daemon eww ya responda a `ping` (conservando la espera con tope actual)
- [x] 4.7 En `bspwmrc`, añadir `bspc config remove_unplugged_monitors true` y `bspc config remove_disabled_monitors true`
- [x] 4.8 Verificar que `bspc wm -r` repetido con ventanas abiertas no pierde ni mueve ventanas y deja `I..VI` en `eDP` y `VII..X` en el externo

## 5. Listener de hotplug

- [x] 5.1 Crear `~/.config/bspwm/scripts/monitors/monitor_hotplug.sh`: pidfile en `$XDG_RUNTIME_DIR` que mata la instancia previa, `bspc subscribe monitor_add monitor_remove monitor_geometry`, debounce de ~0.5 s y llamada a `setup_monitors.sh` al terminar cada ráfaga
- [x] 5.2 Lanzarlo en segundo plano desde `bspwmrc` (con la redirección a `ERROR_LOG` habitual) y comprobar que tras varios `bspc wm -r` solo hay una instancia
- [x] 5.3 Probar en caliente: activar `HDMI-A-0` con xrandr y comprobar que recibe `VII..X`, 6 barras y su trigger. Abrir ventanas en `VIII`, ejecutar `xrandr --output HDMI-A-0 --off` y comprobar que `eDP` tiene `I..X` con esas ventanas y solo 6 barras. Reactivarlo y comprobar que `VII..X` vuelven al externo con sus ventanas
- [x] 5.4 Cambiar la posición o resolución del externo con xrandr y comprobar que barras y trigger se recolocan

## 6. Spotify en ambas pantallas

- [x] 6.1 En `~/.config/eww/player/player.yuck`, declarar el argumento `monitor` en `player-trigger` y reenviarlo en `:onhover`/`:onhoverlost` del trigger y del panel (`${hover} show ${monitor}` / `hide ${monitor}`)
- [x] 6.2 En `~/.config/bspwm/scripts/player/hover_player.sh`, aceptar el monitor como segundo argumento: guardar en el fichero de estado el monitor del panel abierto, abrir `player-panel` con `--screen <mon>`, y si llega `show` de otro monitor, cerrar y reabrir el panel allí. Mantener el guard de no-op y la lógica de gracia y animación, y actualizar el comentario de cabecera
- [x] 6.3 Ajustar `pointer_over_player` si el spike mostró que el título X cambia con `--id`
- [x] 6.4 En `setup_monitors.sh`, cerrar todos los `player-trigger-*` activos (`eww active-windows`) y abrir uno por monitor con `--id player-trigger-<mon> --screen <mon> --arg monitor=<mon>`
- [x] 6.5 Verificar que el hover en el trigger de cada monitor despliega el panel en ese monitor y no en el otro, que pasar de un trigger al otro mueve el panel, y que al retirar el puntero el panel se colapsa y se cierra sin dejar una ventana fantasma que bloquee clicks

## 7. Cierre

- [x] 7.1 Copiar al repo los archivos vivos modificados y los nuevos `bspwm/scripts/monitors/*`, y revisar el diff frente al baseline
- [x] 7.2 Actualizar el README del repo con el soporte multi-monitor (reparto de escritorios, hotplug, foco por hover) y la limitación de un solo externo
- [x] 7.3 Ejecutar `openspec validate add-multi-monitor-bars-and-hover-focus` y commitear
