## Why

Hoy el panel de Spotify solo se abre con `super + ctrl + s`. Es rápido si te acuerdas del atajo, pero no hay nada en pantalla que insinúe que el panel existe, y para una mirada de dos segundos —¿qué está sonando?— exigir una combinación de teclas es más fricción de la que el gesto merece.

La barra tiene un hueco libre de **164px** (medido: `x 1078..1242`, entre el módulo central y `updates`) justo donde cabría un indicador. Un icono de Spotify ahí, que despliegue el panel al pasar el ratón y lo repliegue al salir, convierte el panel en algo visible y alcanzable sin teclado.

## What Changes

- **Nuevo icono de Spotify en la barra**, como ventana de EWW superpuesta sobre el hueco libre. Tiene que ser EWW y no un módulo de Polybar porque **Polybar no tiene concepto de hover**: sus módulos solo entienden click y scroll.
- **Despliegue por hover** con un `revealer` y transición `slidedown`, que baja el panel desde la barra y lo repliega al salir el ratón.
- **Disparador y panel en la misma ventana**, con el `eventbox` envolviendo a ambos. Si fueran dos ventanas, bajar el ratón del icono al panel saldría del disparador y lo cerraría antes de poder usarlo.
- **Retardo de gracia antes de replegar**, porque GTK emite eventos de salida al cruzar sobre los botones hijos del propio panel. Sin eso, mover el ratón hacia el botón de siguiente cerraría el panel.
- **Convivencia con el atajo**: la ventana `music` que abre `super + ctrl + s` se queda como está. Ambas reutilizan el mismo `defwidget` `player`, sin duplicar la interfaz.
- **El botón de cerrar pasa a ser opcional** en el widget: tiene sentido en la ventana del atajo, pero no en una que se gobierna por hover.
- **Apertura al inicio de sesión**, para que el icono esté siempre en la barra.

Fuera de alcance: mover o reemplazar módulos de Polybar, y cualquier cambio al contenido del panel.

## Capabilities

### New Capabilities

- `player-hover-trigger`: indicador permanente en la barra que despliega y repliega el panel de Spotify según la posición del ratón, incluyendo su ubicación sobre el hueco de la barra, la semántica de despliegue y repliegue, y su arranque con la sesión.

### Modified Capabilities

- `spotify-widget`: el widget del reproductor acepta que su botón de cerrar sea opcional, para poder reutilizarlo en una ventana gobernada por hover.

## Impact

**Archivos nuevos:**
- `.config/bspwm/scripts/player/hover_player.sh`: aplica el estado de hover con retardo de gracia, siguiendo el patrón de temporizador único de `show_volume_widget.sh`

**Archivos modificados:**
- `.config/eww/player/player.yuck`: nueva ventana con el icono y el `revealer`, variable de estado del hover, y parámetro del botón de cerrar en `defwidget player`
- `.config/eww/player/player.scss`: estilo del icono disparador
- `.config/bspwm/bspwmrc`: abrir la ventana del disparador al arrancar la sesión
- `README.md`: documentar el indicador y su comportamiento

**Dependencias:** ninguna nueva.

**Riesgos:**
- GTK emite `leave-notify` al cruzar el ratón sobre widgets hijos; sin el retardo de gracia el panel parpadearía justo al ir a pulsar un botón.
- La ventana queda superpuesta sobre la barra de Polybar y debe apilarse por encima sin robar el foco ni bloquear clics en los módulos vecinos.
- La ventana cambia de tamaño al desplegarse; el anclaje debe elegirse para que el panel no se salga de la pantalla.
- Si los módulos de la barra cambian de ancho, el hueco se mueve y el icono queda mal colocado; la posición se mide, no se deduce de la configuración.
