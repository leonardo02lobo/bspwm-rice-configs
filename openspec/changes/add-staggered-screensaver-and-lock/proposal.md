## Why

El laptop viaja a todas partes y hoy la sesión **no se bloquea nunca**. Lo único que ocurre es que DPMS apaga la pantalla a los 10 minutos (`xset q`: `Standby/Suspend/Off: 600`); basta mover el ratón para entrar. `super + F12` suspende sin bloquear, y cerrar la tapa suspende (`HandleLidSwitch=suspend` por defecto) también sin bloquear. Cualquiera que abra el equipo está dentro.

Al mismo tiempo, el rice tiene de qué presumir cuando está en reposo: `get_player_state.sh` ya entrega título, artista, estado y la **ruta local de la carátula cacheada**. Una pantalla de reposo que muestre reloj y lo que suena no necesita datos nuevos, solo pintarlos.

Son dos necesidades distintas —seguridad y decoración— y conviene construirlas como dos capas, no como una.

## What Changes

- **Detección de inactividad con `xss-lock`**, que se engancha al temporizador de X *y* a systemd-logind. Eso cubre de un golpe tres puertas que hoy están abiertas: inactividad, `super + F12` y cierre de tapa, porque logind avisa antes de dormir.
- **Escalonado en tres tramos**: a los 5 minutos aparece la pantalla de reposo, a los 10 se bloquea de verdad, a los 15 DPMS apaga el panel.
- **Capa decorativa en EWW**, a pantalla completa y **una ventana por monitor conectado**, con reloj y lo que está sonando sobre la carátula del disco. Es puramente cosmética y siempre precede al bloqueo; nunca es lo que protege.
- **Bloqueo con el `i3lock` ya instalado**, que resulta ser `i3lock-color 2.13.c.5` y trae reloj, anillo y fuentes de forma nativa. No hace falta instalar nada para que se vea bien.
- **Desactivar `xfce4-screensaver`**, instalado y registrado en `/etc/xdg/autostart/`, además de activable por D-Bus. Dos bloqueadores compitiendo es peor que ninguno.
- **Interruptor manual de inhibición** con atajo e indicador en la barra, para cuando estés viendo algo y no quieras que se bloquee.
- **Bloqueo sin captura de pantalla**: `i3lock-color` puede difuminar una captura del escritorio, y en un equipo que viaja eso deja a la vista la forma de lo que tenías abierto. Se usa el fondo de escritorio.

Fuera de alcance: un servicio D-Bus propio que atienda `org.freedesktop.ScreenSaver` (ver `design.md`), apagado por batería, y cualquier cambio a las transiciones de escritorio existentes.

## Capabilities

### New Capabilities

- `session-lock`: detección de inactividad, bloqueo de la sesión, cobertura de suspensión y cierre de tapa, garantía de un único bloqueador, e inhibición manual.
- `idle-screensaver`: capa decorativa a pantalla completa mostrando hora y reproducción, su presencia en cada monitor y su desaparición ante cualquier actividad.

### Modified Capabilities

Ninguna. `multi-monitor-desktop` cubre barras y escritorios por monitor, que son permanentes; estas ventanas son transitorias y se enumeran en el momento, así que no tocan sus requisitos.

## Impact

**Archivos nuevos:**
- `.config/bspwm/scripts/idle/screensaver.sh`: abre y cierra la capa decorativa, una ventana por salida conectada
- `.config/bspwm/scripts/idle/lock.sh`: invoca `i3lock` con el aspecto del rice
- `.config/bspwm/scripts/idle/inhibit.sh`: alterna la inhibición y expone su estado a la barra
- `.config/eww/screensaver/screensaver.yuck` y `.scss`: la pantalla de reposo

**Archivos modificados:**
- `.config/bspwm/bspwmrc`: temporizadores `xset`, arranque de `xss-lock`, desactivación de `xfce4-screensaver`
- `.config/sxhkd/sxhkdrc`: atajo de bloqueo inmediato y atajo de inhibición
- `.config/eww/eww.yuck` y `eww.scss`: incluir la pantalla de reposo
- `~/.config/polybar/`: indicador de inhibición — **fuera del repo, edición manual**
- `README.md`

**Dependencias nuevas:** `xss-lock` (0.4.0-1, en repos). Ya están `i3lock-color`, `xset`, `eww`, `xrandr`.

**Riesgos:**
- La relación exacta entre `xset s <timeout> <cycle>` y el momento en que `xss-lock` lanza el notificador y el bloqueador hay que **medirla**, no deducirla de la documentación.
- Los navegadores piden no bloquear a través de `org.freedesktop.ScreenSaver`, que hoy **no tiene dueño**: ver vídeo en el navegador no inhibe nada. `mpv` sí usa la extensión nativa de X y queda cubierto.
- Una pantalla de reposo que no se limpie al terminar deja ventanas a pantalla completa colgadas sobre la sesión.
