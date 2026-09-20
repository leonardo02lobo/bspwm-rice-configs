## Context

El panel de Spotify ya funciona: `defwidget player` con metadata en vivo, controles, carátula y estado sin reproductor, dentro de la ventana `music` que abre `super + ctrl + s` anclada bajo la barra.

Lo que falta es una forma de llegar a él sin teclado. Dos hechos del entorno acotan las opciones:

- **Polybar no emite hover.** Sus módulos solo soportan `click-*` y `scroll-*`. No hay forma de que la barra avise de que el ratón está encima de un módulo, así que el disparador no puede ser un módulo.
- **eww 0.6 sí tiene lo necesario**, verificado en el binario instalado: `onhover`, `onhoverlost`, `revealer` y las transiciones `slideright slideleft slideup slidedown fade crossfade none`.

Geometría medida con `xwininfo` sobre las ventanas vivas de Polybar:

```
x    7 .. 1915   log (principal_bar, la barra de fondo, y 12..60)
x  833 .. 1078   primary_bar
x 1078 .. 1242   ← 164px libres
x 1242 .. 1338   updates
x 1347 .. 1539   date
x 1549 .. 1852   target_to_hack
x 1860 .. 1908   primary (botón de apagado)
```

## Goals / Non-Goals

**Goals:**

- Que el panel sea visible y alcanzable sin teclado, y que su existencia se note.
- Que el gesto completo —entrar, leer, pulsar un botón, salir— funcione sin que el panel se cierre a destiempo.
- Reutilizar el panel existente sin duplicar su definición.

**Non-Goals:**

- **Reemplazar el atajo.** Conviven; son dos ventanas independientes sobre el mismo `defwidget`.
- **Tocar los módulos de Polybar.** El icono se superpone al hueco, no se integra en la barra.
- **Cambiar el contenido del panel.** Este change solo añade una forma de invocarlo.

## Decisions

### 1. Dos ventanas, ambas escuchando el hover

El icono y el panel son ventanas separadas. Las dos envuelven su contenido en un `eventbox` con `onhover`/`onhoverlost`, y las dos llaman al mismo script, que mantiene un único repliegue pendiente.

**Por qué no una sola ventana, que era la intención original:** eww reserva el ancho del hijo del `revealer` aunque esté replegado. Medido en vivo, la ventana única daba `365x30` en `x 865..1230` —montándose sobre el módulo `primary_bar`, que ocupa hasta `x 1078`, y convirtiendo esa franja entera en zona de hover—, mientras que sin el `revealer` daba `29x18` en `x 1201..1230`, justo dentro del hueco. Poner `:visible false` sobre el `revealer` no libera ese ancho, ni cerrando y reabriendo la ventana.

**Qué resuelve entonces el problema del menú por hover:** el retardo de gracia de la decisión 2, que de todas formas hacía falta. Al bajar del icono al panel, el puntero abandona la primera ventana y arma un repliegue a 300ms; al entrar en la segunda, ese repliegue se cancela. Los ~27px de pantalla desnuda entre ambas se cruzan en mucho menos que eso.

```
┌─ ventana 1: icono ─┐   salir → repliegue pendiente (300ms)
└────────────────────┘
        ↓ ~27px
┌─ ventana 2: revealer ─────┐   entrar → cancela el repliegue
│  panel                     │
└────────────────────────────┘
```

**La ventana del panel se cierra tras replegarse**, no se deja abierta con el `revealer` cerrado. eww no encoge el toplevel cuando su contenido se colapsa: medido, la ventana se queda en `365x176` y `xwininfo` confirma que no tiene forma de entrada definida, así que esa región invisible se tragaría todos los clics de lo que haya debajo. El script repliega, espera a que termine la animación y entonces cierra; al desplegar, abre y espera un instante a que la ventana se realice para que la animación se vea.

### 2. `show` idempotente: `eww open` recrea la ventana y realimenta el hover

`show` no hace nada si el panel ya está desplegado.

**Por qué:** `eww open` sobre una ventana ya abierta **la destruye y la crea de nuevo** —comprobado, el id de ventana X cambia de `0x3a34576` a `0x3a34581`—. Con el puntero encima, esa ventana nueva emite un `enter` inmediato, que llama a `onhover`, que vuelve a llamar a `eww open`. Medido con `xdotool`: un solo gesto de hover producía **36 invocaciones**, con `show` disparándose cada ~55ms mientras el puntero estaba completamente quieto. Con la guarda, el mismo gesto son 4.

### 3. El repliegue se decide consultando dónde está el puntero, no cancelando

Tras el retardo de gracia, el script pregunta a X la posición del puntero y aborta el repliegue si cae sobre el icono, sobre el panel, o en el corredor entre ambos.

**Por qué no cancelar desde `show`:** se intentó dos veces y las dos perdieron la misma carrera. Como el icono y el panel son ventanas distintas, bajar de uno a otro dispara `hide` y `show` en el mismo milisegundo, sin orden garantizado entre dos procesos independientes. Matando el pid, `show` leía el pidfile del ciclo anterior —`hide` solo puede escribirlo *después* de lanzar el subproceso— y mataba a un muerto. Con un token de generación, `show` lo borraba antes de que `hide` lo escribiera. En ambos casos el panel se colapsaba 0.3s después de que el puntero llegara a él.

La posición del puntero no depende del orden de los eventos y es, literalmente, lo que queremos saber.

**Detalle:** X informa `WINDOW=0` para estas ventanas, por ser `wm-ignore`, así que no sirve identificarlas por id; se comparan los rectángulos que da `xwininfo`. El corredor de 27px entre el icono y el panel se cubre con un margen de 30px, para que detenerse a mitad de camino no cierre el panel.

**Coste:** dos consultas a X por repliegue, no por evento de hover. El camino rápido —el puntero quieto sobre el panel— no ejecuta nada.

**Retardo de gracia:** sigue existiendo, ahora en su papel legítimo, absorber los `leave` que GTK emite al cruzar hacia los botones hijos, y dar tiempo al viaje entre ventanas.

### 3. La posición se mide, no se deduce de la configuración

El icono se coloca dentro del hueco `x 1078..1242` medido con `xwininfo`.

**Por qué:** ya hubo un error por leer `config.ini`, que Polybar nunca carga, y colocar el panel 14px dentro de la barra. La única fuente fiable de dónde está cada módulo son las ventanas reales.

**Consecuencia asumida:** si algún módulo de la barra cambia de ancho, el hueco se desplaza y el icono queda descolocado. Se documenta junto al valor, igual que el offset vertical del panel.

### 4. Anclaje que deja crecer la ventana sin salirse de la pantalla

La ventana se ancla arriba a la derecha, con el desplazamiento que sitúa el icono en el hueco. Al desplegarse, el panel crece hacia abajo y hacia la izquierda, porque el borde derecho queda fijado.

**Por qué:** el panel mide 365px de ancho y el icono unos 40px. Si la ventana creciera hacia la derecha desde el hueco, el borde llegaría a ~1600px, que cabe, pero quedaría descolgado bajo los módulos de fecha y objetivo. Creciendo hacia la izquierda queda bajo el hueco y el módulo central, que es espacio visualmente libre.

**A verificar en pantalla:** es una decisión estética; si el panel colgando a la izquierda del icono se ve raro, el anclaje es una línea.

### 5. El botón de cerrar pasa a ser un parámetro del widget

`defwidget player` recibe un parámetro que controla si se muestra el botón de cerrar, activo en la ventana `music` y desactivado en la del hover.

**Por qué:** ese botón ejecuta `eww close music`. En la ventana del hover cerraría la *otra* ventana, que es un comportamiento absurdo. Y un botón de cerrar en un panel que ya se cierra solo al salir el ratón no aporta nada.

**Alternativa considerada:** parametrizar el nombre de la ventana a cerrar. Se descarta: no resuelve que el botón sobra en una interfaz gobernada por hover.

### 6. Convivencia sin coordinación entre las dos ventanas

Las dos ventanas son independientes: `music` la gobierna el atajo, la del hover el ratón. Ninguna sabe de la otra.

**Por qué:** coordinarlas —cerrar una al abrir la otra— exige estado compartido y reglas para casos que casi no ocurren. Que ambas puedan verse a la vez es un efecto visual raro pero inofensivo, y el coste de evitarlo supera al del problema.

**Sin coste de rendimiento:** las dos ventanas leen la misma variable `player`, que es un único `defpoll` global. Dos ventanas no significan dos sondeos.

### 7. Apertura desde `bspwmrc`, junto al resto de daemons

La ventana se abre en el arranque de sesión, donde ya se lanza el daemon de eww.

**Por qué:** el icono tiene que estar siempre, como un módulo más de la barra. Y debe abrirse con `-c` explícito, porque en esta máquina corre un segundo daemon de eww para el widget de `display-manager`.

**Detalle de arranque:** la apertura tiene que tolerar que el daemon aún no esté listo cuando `bspwmrc` llega a esa línea.

## Risks / Trade-offs

- **Eventos de salida espurios de GTK al cruzar sobre botones** → mitigado por el retardo de gracia de la decisión 2; es la razón de que ese retardo exista y no un adorno.
- **La ventana se superpone a la barra** → se apila como overlay, sin foco, y ocupa solo el hueco libre, así que no tapa ningún módulo ni intercepta sus clics.
- **El hueco se mueve si cambian los módulos** → documentado; la posición se remide con `xwininfo`.
- **Dos ventanas pueden mostrar el panel a la vez** → aceptado conscientemente en la decisión 6.
- **Cada cambio de hover lanza un proceso** (`eww update`) → son eventos de interacción humana, no un bucle; el coste es despreciable frente al `defpoll` que ya corre cada segundo.
- **Un icono permanente sobre la barra podría estorbar visualmente** → ocupa un hueco que hoy está vacío, y es lo que hace descubrible la función.

## Migration Plan

1. Parametrizar el botón de cerrar y comprobar que la ventana `music` sigue igual que ahora.
2. Añadir la variable de hover y el script con el retardo, y verificarlos a mano con `eww update` antes de cablear el `eventbox`.
3. Añadir la ventana del disparador y posicionarla, midiendo con `xwininfo` que cae en el hueco.
4. Cablear el hover y verificar el gesto completo: entrar, bajar al panel, pulsar un botón, salir.
5. Abrirla desde `bspwmrc` y comprobarlo reiniciando la sesión.

**Rollback:** revertir el commit y cerrar la ventana; la del atajo no depende de nada de esto.

## Open Questions

- ¿Cuánto retardo de gracia? Arrancar en 300ms y ajustar: demasiado corto parpadea, demasiado largo deja el panel colgando tras salir.
- ¿El icono debe indicar el estado de reproducción —por ejemplo cambiar de color al estar pausado— o mantenerse neutro?
- ¿El panel desplegado a la izquierda del icono se ve bien, o conviene anclarlo de otra forma?
