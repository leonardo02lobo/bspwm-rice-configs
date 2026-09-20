## Why

El widget de Spotify ya está construido alrededor de la carátula: `.player-art` tiene `background-size: cover` y un `.player-info` con degradado encima, diseñado para leerse sobre una imagen. Pero esa imagen nunca aparece, porque el estilo apunta directo a la URL remota de MPRIS y **GTK no carga URLs remotas en CSS**. El resultado es un panel con un hueco de fondo plano donde el diseño esperaba una portada.

El dato está ahí y es bueno: `mpris:artUrl` devuelve un JPEG de **640x640** en `i.scdn.co`, accesible (`HTTP 200`) y descargable en **~0.85s**. Solo falta el intermediario que lo baje a disco.

El change `add-spotify-floating-widget` dejó esto explícitamente como no-objetivo y candidato a una segunda iteración; esta es esa iteración.

## What Changes

- **Cachear la carátula en disco** con un script que, dada la pista actual, garantiza un archivo local con su portada y devuelve su ruta.
- **Cachear por identidad de pista, no por tiempo**: el nombre del archivo deriva de `mpris:trackid`, que ya viene en la metadata, así que volver a una canción ya escuchada no descarga nada.
- **Descargar fuera del ciclo de poll**: el `defpoll` del widget corre cada segundo, y una descarga de ~0.85s dentro del poll congelaría el panel en cada cambio de pista. La descarga ocurre en segundo plano y el widget muestra la portada en el tick siguiente.
- **Ampliar el snapshot JSON** (`get_player_state.sh`) con la ruta local de la carátula, o cadena vacía mientras no exista.
- **Pintar la portada** rellenando el `background-image` de `.player-art` con la ruta local, que es para lo que ese contenedor ya estaba diseñado.
- **Degradar sin imagen**: mientras la descarga está en curso, si falla, o con Spotify cerrado, el panel se ve exactamente como hoy.

Fuera de alcance: el video (Spotify Canvas no se expone por MPRIS ni por la Web API, y eww no reproduce video), efectos sobre la portada como desenfoque de fondo, y cualquier visualizador de audio.

## Capabilities

### New Capabilities

- `album-art-cache`: obtención y cacheo en disco de la carátula de la pista en reproducción, con identidad por pista, descarga no bloqueante, escritura atómica y un límite de tamaño del caché.

### Modified Capabilities

- `spotify-control`: el snapshot de estado añade un campo con la ruta local de la carátula.
- `spotify-widget`: el panel pinta la carátula cuando existe y mantiene su aspecto actual cuando no.

## Impact

**Archivos nuevos:**
- `.config/bspwm/scripts/player/get_album_art.sh`: resuelve la ruta de caché de una pista, dispara la descarga en segundo plano si falta

**Archivos modificados:**
- `.config/bspwm/scripts/player/get_player_state.sh`: añade el campo de carátula al JSON
- `.config/eww/player/player.yuck`: devuelve el `:style` con `background-image` al `.player-art`, ahora con ruta local
- `README.md`: documentar el directorio de caché

**Dependencias:** ninguna nueva. `curl` y `jq` ya se usan en el rice.

**Riesgos:**
- El caché crece con cada pista nueva (~60KB por portada); necesita un tope para no crecer sin límite.
- GTK puede cachear imágenes de CSS por URL, pero como cada pista produce una ruta distinta, una portada nueva nunca reutiliza la entrada de otra.
- Depende de que `i.scdn.co` sea alcanzable; sin red, el panel simplemente se ve como hoy.
