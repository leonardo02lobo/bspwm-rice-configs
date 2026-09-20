## Context

El widget ya tiene el hueco hecho. `.player-art` existe con `background-size: cover`, `border-radius` y un `.player-info` con degradado `rgb(#191919) → rgba(#262626, 0.5)` encima, que solo tiene sentido si detrás hay una imagen. El change anterior quitó el `:style` que apuntaba a la URL remota porque nunca cargaba; el contenedor quedó con fondo plano.

Los datos medidos sobre la sesión real:

```
mpris:artUrl    https://i.scdn.co/image/ab67616d0000b273...   HTTP 200, image/jpeg, 640x640
descarga        ~0.85 s
mpris:trackid   /com/spotify/track/0QvmWZeyks41359inOe41X
```

La resolución que entrega MPRIS ya es la buena (640x640), así que no hace falta tocar la URL.

La restricción que manda sobre todo el diseño: el widget se alimenta de un `defpoll` cada segundo (`get_player_state.sh`). Cualquier trabajo que ese script haga de forma síncrona se paga en cada tick, y 0.85s de red dentro de un poll de 1s dejaría el panel congelado en cada cambio de pista.

Existe un precedente de red en el rice, `profilecard/scripts/Weather`, que hace `curl` sin cachear nada — precisamente lo que aquí no se puede hacer.

## Goals / Non-Goals

**Goals:**

- Ver la portada de lo que suena, en el sitio para el que el widget ya estaba diseñado.
- No introducir latencia en el ciclo de poll.
- No descargar dos veces la misma portada.
- Que la ausencia de imagen (descargando, sin red, sin Spotify) se vea como el panel de hoy, no como un error.

**Non-Goals:**

- **Video / Spotify Canvas.** No se expone por MPRIS ni por la Web API pública; los proyectos que lo obtienen usan un endpoint interno con protobuf y un token extraído del cliente. Además eww no reproduce video.
- **Efectos sobre la portada** (fondo desenfocado, transiciones animadas).
- **Visualizador de audio.** Es otra conversación, con otra herramienta (`cava`).
- **Reescribir la URL del CDN** para pedir otra resolución: los prefijos de tamaño de `i.scdn.co` son comportamiento no documentado, y 640x640 ya sobra para un panel de 365px.

## Decisions

### 1. Cachear por identidad de pista, no por tiempo

El nombre del archivo deriva de `mpris:trackid`, que ya viene en la metadata.

**Por qué:** la portada de una pista no cambia nunca, así que no hay nada que invalidar. Un caché por TTL volvería a descargar la misma imagen sin motivo, y uno por URL obligaría a normalizar la URL. Con el id de pista, volver a una canción ya escuchada es un acierto de caché inmediato.

**Detalle:** el id viene como ruta D-Bus (`/com/spotify/track/0Qvm...`); se usa el último segmento, que es el id base62 de Spotify y es seguro como nombre de archivo.

### 2. La descarga ocurre fuera del poll

El script de estado nunca espera a la red. Si el archivo ya está, devuelve su ruta; si no, lanza la descarga en segundo plano y devuelve cadena vacía. El tick siguiente, un segundo después, ya la encuentra.

```
tick N     archivo ausente  →  lanza descarga en background  →  devuelve ""
            (panel sin portada, como hoy)
tick N+1   archivo presente →  devuelve la ruta              →  aparece la portada
```

**Por qué no hacerlo síncrono:** 0.85s dentro de un poll de 1s congelaría el panel en cada cambio de pista, que es justo el momento en que el usuario lo está mirando.

**Alternativa considerada:** un daemon que escuche cambios de pista con `playerctl --follow` y descargue de forma reactiva. Es más elegante y evita el retardo de un tick, pero añade un proceso de larga vida al arranque, con su ciclo de vida y sus fallos. El retardo de un segundo no lo justifica.

### 3. Escritura atómica, con descarga a un archivo temporal

Se descarga a `<id>.part` y solo al terminar se renombra a `<id>.jpg`.

**Por qué:** sin esto, el poll puede encontrarse un JPEG a medio escribir y GTK intentaría pintar una imagen truncada. El `mv` dentro del mismo sistema de archivos es atómico, así que el archivo final o no existe o está completo.

**Efecto colateral útil:** la presencia de `<id>.part` sirve de candado. Si el tick siguiente ve que ya hay una descarga en curso, no lanza otra.

### 4. Marcar los fallos para no reintentar cada segundo

Si la descarga falla, se borra el `.part` y se deja un `<id>.fail` con la hora. El lanzador ignora la pista mientras ese marcador tenga menos de 60 segundos.

**Por qué:** sin esto, estar sin red significa un `curl` por segundo, indefinidamente, mientras el panel esté abierto. Con el marcador, el reintento es una vez por minuto.

### 5. Caché en `~/.cache`, con tope de entradas

El directorio es `${XDG_CACHE_HOME:-$HOME/.cache}/eww/player-art`, y tras cada descarga exitosa se conservan las 100 entradas más recientes.

**Por qué ahí y no en `/tmp`:** sobrevive al reinicio, que es exactamente lo que se quiere de un caché de contenido inmutable, y es la ubicación estándar para datos regenerables.

**Por qué el tope:** a ~60KB por portada, 100 entradas son unos 6MB, suficiente para el repertorio habitual de una sesión sin crecer sin límite. Es un `ls -t` con un `rm`, no una política de expiración.

### 6. Pintar con `background-image`, no con el widget `image`

Se devuelve el `:style` con `background-image: url("file://...")` sobre `.player-art`.

**Por qué:** es para lo que el contenedor ya está construido — portada de fondo con el texto legible encima gracias al degradado. Usar el widget `image` significaría reestructurar el panel para poner la carátula al lado del texto, que es otro diseño, no este.

**Sobre el caché de GTK:** GTK cachea imágenes de CSS por URL, lo que normalmente da imágenes obsoletas al cambiar un archivo. Aquí no aplica: cada pista tiene una ruta distinta, y el contenido de una ruta dada nunca cambia.

### 7. La ausencia de imagen no es un caso de error

Con cadena vacía, el `:style` queda sin `background-image` y el panel se ve como hoy. Cubre los tres casos — descarga en curso, sin red, Spotify cerrado — con la misma rama.

**Por qué no una imagen de reserva:** habría que crearla, versionarla y elegir un aspecto; el fondo plano actual ya es un estado visual aceptable, y así no hay parpadeo entre una imagen genérica y la real.

## Risks / Trade-offs

- **La portada aparece un segundo tarde al cambiar de pista** → aceptado a cambio de no congelar el panel; si molesta, la alternativa es el daemon con `playerctl --follow` de la decisión 2.
- **Un `.part` huérfano bloquea la descarga de esa pista** (si el proceso muere a mitad) → el script debe tratar como obsoleto un `.part` con más de un minuto de antigüedad.
- **El caché crece hasta el tope en disco del usuario** → 6MB acotados y en `~/.cache`, que es borrable sin consecuencias por definición.
- **Depende de un CDN externo** → sin red no hay portada, pero el panel sigue funcionando; ningún control depende de la imagen.
- **Títulos y portadas de pistas locales o podcasts** pueden no traer `artUrl` → se trata igual que un fallo: sin imagen, sin error.

## Migration Plan

1. Escribir el script de caché y verificarlo a mano contra la pista en reproducción, antes de tocar el widget.
2. Añadir el campo al snapshot JSON y comprobar que sigue siendo JSON válido en los tres estados (con portada, descargando, sin reproductor).
3. Devolver el `:style` al widget.
4. Verificar el cambio de pista en vivo: portada nueva al segundo, sin congelación del panel.

**Rollback:** revertir el commit; el caché en `~/.cache` queda huérfano y se puede borrar a mano.

## Open Questions

- ¿El retardo de un tick al cambiar de pista se nota lo suficiente como para justificar el daemon reactivo? Se decide viéndolo.
- ¿100 entradas es el tope correcto, o conviene menos? Depende de cuánta música distinta pase por una sesión.
- ¿Conviene que la portada se vea también en algún otro sitio (por ejemplo en las notificaciones de dunst al cambiar de pista)? Sería reutilizar el mismo caché, pero es otro alcance.
