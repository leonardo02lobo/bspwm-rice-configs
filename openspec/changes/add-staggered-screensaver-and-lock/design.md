## Context

Estado medido de la sesión, no supuesto:

```
xset q        Screen Saver timeout 600, prefer blanking yes
              DPMS Standby/Suspend/Off 600, Enabled
logind        todo por defecto → HandleLidSwitch=suspend, IdleAction=ignore
sxhkdrc       super + F12 → systemctl suspend   (sin bloqueo)
              ningún atajo de bloqueo
xrandr        eDP primary 1920x1080+0+0 · HDMI-A-0 1920x1080+1920+0
```

Instalado y relevante: `i3lock` que en realidad es **`i3lock-color 2.13.c.5`** (trae `--blur`, `--radius`, `--time-str`, `--date-str`, `--screen`), `slock`, `xwinwrap`, `mpv`, `feh`, `picom` corriendo, y **`xfce4-screensaver 4.20.2-1`** instalado con su `.desktop` en `/etc/xdg/autostart/` y activable por D-Bus (`org.xfce.ScreenSaver` aparece como *activatable*). Nadie posee `org.freedesktop.ScreenSaver`.

Falta, y está en repos: `xss-lock 0.4.0-1`.

El rice ya resuelve lo multi-monitor con `setup_monitors.sh` (reconciliación idempotente de escritorios, barras y triggers), invocado por `bspwmrc` y por el listener de hotplug.

## Goals / Non-Goals

**Goals:**

- Que abrir el laptop ajeno no dé acceso a la sesión, venga el reposo de la inactividad, de la tapa o de `super + F12`.
- Que el reposo se vea como el resto del rice y aproveche lo que ya existe.
- Que ver algo sin tocar el teclado no acabe en un bloqueo.
- Que nada quede colgado en pantalla cuando el reposo termina.

**Non-Goals:**

- **Un servicio D-Bus propio para `org.freedesktop.ScreenSaver`.** Ver decisión 7.
- **Apoyarse en `xfce4-screensaver`.** Es una solución completa, pero no es moldeable al aspecto del rice y colisiona con el bloqueador propio.
- **Políticas por batería o por aplicación.**
- **Tocar las transiciones de escritorio** de `desktop-window-transitions`.

## Decisions

### 1. `xss-lock` como detector, no `xautolock` ni un bucle propio

**Por qué:** `xss-lock` escucha el temporizador de X *y* las señales de systemd-logind. Eso significa que el bloqueo aparece **antes de dormir**, así que `super + F12` y el cierre de tapa quedan cubiertos sin tocar `logind.conf` ni añadir atajos nuevos. Con `xautolock` habría que cablear la suspensión aparte, y con un bucle propio sobre `xprintidle` habría que reimplementar ambas cosas.

**Coste asumido:** una dependencia nueva, de 0.4.0 y en los repos oficiales.

### 2. El escalonado sale del notificador de `xss-lock`, y sus tiempos se miden

`xss-lock` admite un *notificador* que corre al activarse el salvapantallas de X y que muere cuando arranca el bloqueador o cuando vuelve la actividad. Ese es exactamente el mecanismo del escalonado: notificador = capa decorativa, bloqueador = `i3lock`.

```
 0 ────────── 5 min ─────────── 10 min ────────── 15 min
 actividad    notificador        bloqueador        DPMS off
              (eww, decorativa)  (i3lock)
```

**Lo que hay que medir:** cómo se traduce `xset s <timeout> <cycle>` en el instante del notificador y el del bloqueador. La documentación admite más de una lectura y ya nos ha pasado dar por buenos valores de un archivo que nadie cargaba. Se fija con un cronómetro antes de dejar los tiempos definitivos.

### 3. La capa decorativa nunca es la que protege

Las ventanas de eww no retienen el teclado ni el puntero: se pueden cerrar. El bloqueo real lo hace `i3lock`, que hace *grab* de ambos. La capa decorativa **siempre precede** al bloqueador y muere cuando este arranca.

**Por qué importa decirlo:** es la confusión habitual al montar esto. Si lo bonito hiciera de guardián, no habría guardián.

### 4. Una ventana por salida, enumeradas en el momento

El script del notificador consulta `xrandr` y abre una ventana a pantalla completa por cada salida conectada, con `--screen`.

**Por qué no en `setup_monitors.sh`:** ahí viven las ventanas **permanentes** —barras y triggers—, que se reconcilian en cada evento de monitor. Estas son transitorias: existen solo durante el reposo. Mezclarlas obligaría a `setup_monitors.sh` a razonar sobre si la sesión está inactiva, que no es asunto suyo.

**Caso límite aceptado:** si conectas o desconectas un monitor con el reposo ya en pantalla, la capa decorativa no se reajusta. El bloqueo sí, porque `i3lock` cubre toda la pantalla X.

### 5. Limpieza obligatoria al terminar

El notificador recibe `SIGTERM` cuando vuelve la actividad o cuando arranca el bloqueador, y debe cerrar sus ventanas en ese momento.

**Por qué:** sin una trampa explícita, al volver te encuentras ventanas a pantalla completa tapando la sesión. Es el fallo más probable de toda esta función, y es de una línea evitarlo.

### 6. Bloqueo sin captura de pantalla

`i3lock-color` sabe difuminar una captura del escritorio, y queda precioso. No se usa.

**Por qué:** un desenfoque sigue dejando ver la forma de lo que tenías abierto —qué ventanas, cuántas, un documento, una conversación— y este equipo se bloquea en sitios públicos. Se usa el fondo de escritorio, que no revela nada de la sesión. La hora y el anillo sí, que son nativos de `i3lock-color`.

### 7. Inhibición manual, y el hueco documentado

Un atajo alterna la inhibición apagando y encendiendo el temporizador de X, con un indicador en la barra.

**Por qué no algo automático:** las aplicaciones piden no bloquear por dos vías distintas. `mpv` usa la extensión de X directamente y **ya queda cubierto**: suspende el temporizador por su cuenta. Los navegadores llaman a `org.freedesktop.ScreenSaver`, un nombre de D-Bus que **hoy no tiene dueño**, así que su petición no llega a nadie. Darle dueño significa escribir y mantener un servicio D-Bus, que es un proyecto aparte y no lo que se pidió.

**Alternativa considerada:** dejar que `xfce4-screensaver` haga de dueño. Se descarta por la decisión 8.

**Consecuencia asumida y documentada:** ver vídeo en el navegador sin tocar nada acabará en bloqueo salvo que se pulse el atajo.

### 8. `xfce4-screensaver` se desactiva

Está instalado, con autoarranque en `/etc/xdg/autostart/` y activable por D-Bus.

**Por qué:** hoy no molesta porque `bspwm` no procesa el autoarranque XDG, pero cualquier aplicación que llame a su interfaz lo despierta, y entonces habría dos bloqueadores peleándose por el *grab* del teclado. Un bloqueo que a veces no acepta tu contraseña es peor que no tener bloqueo, porque crees que estás protegido.

### 9. DPMS después del bloqueo, no antes

Los tiempos quedan 5 / 10 / 15: decorativo, bloqueo, apagado.

**Por qué en ese orden:** si el panel se apagara antes de bloquear, el equipo pasaría un rato aparentando estar apagado mientras sigue desbloqueado — la peor combinación, porque invita a levantarse de la mesa.

## Risks / Trade-offs

- **Quedarte fuera por un bloqueador mal configurado** → se prueba primero el atajo de bloqueo manual, con una sesión abierta en otro TTY como salida de emergencia, antes de enganchar nada automático.
- **Los tiempos de `xss-lock` no son los que uno supone** → se miden con cronómetro (decisión 2) antes de fijarlos.
- **Ventanas decorativas colgadas** → trampa de `SIGTERM` (decisión 5), verificada provocando el reposo y volviendo.
- **Vídeo en navegador interrumpido por el bloqueo** → hueco conocido y documentado, con atajo manual como salida (decisión 7).
- **El indicador de inhibición vive en Polybar, fuera del repo** → igual que el resto de Polybar, se documenta como paso manual.
- **Dos monitores durante el reposo** → la capa decorativa se enumera al arrancar y no reacciona al hotplug (decisión 4); el bloqueo sí cubre todo.

## Migration Plan

1. Instalar `xss-lock` y desactivar `xfce4-screensaver`.
2. Escribir y probar el bloqueo **a mano**, con atajo, antes de automatizar nada.
3. Medir los tiempos del notificador y el bloqueador con valores cortos.
4. Añadir la capa decorativa y su limpieza.
5. Fijar los tiempos definitivos en `bspwmrc` y verificar tapa y `super + F12`.
6. Añadir la inhibición y su indicador.

**Rollback:** matar `xss-lock` devuelve el comportamiento actual; los tiempos se restauran con `xset`.

## Open Questions

- ¿5 / 10 / 15 es el escalonado correcto, o prefieres que el bloqueo llegue antes estando fuera de casa?
- ¿La pantalla de reposo debe apagarse sola si no hay música sonando, o mostrar solo el reloj?
- ¿Quieres un atajo de bloqueo inmediato al estilo `super + shift + Escape`, además del automático?
