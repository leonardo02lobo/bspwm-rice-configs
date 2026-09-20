## 1. Script de caché

- [x] 1.1 Crear `.config/bspwm/scripts/player/get_album_art.sh`, que resuelve el directorio de caché en `${XDG_CACHE_HOME:-$HOME/.cache}/eww/player-art` y lo crea si falta
- [x] 1.2 Derivar el nombre del archivo del último segmento de `mpris:trackid`, e imprimir la ruta cuando el archivo ya existe
- [x] 1.3 Lanzar la descarga en segundo plano cuando falta el archivo, imprimiendo cadena vacía y saliendo de inmediato, sin esperar a la red
- [x] 1.4 Descargar a `<id>.part` y renombrar a `<id>.jpg` solo al completar, de modo que nunca se exponga una imagen a medio escribir
- [x] 1.5 Usar la presencia de `<id>.part` como candado para no lanzar descargas duplicadas, tratando como obsoleto un `.part` de más de un minuto
- [x] 1.6 Registrar los fallos en `<id>.fail` y no reintentar esa pista mientras el marcador tenga menos de 60 segundos
- [x] 1.7 Tras cada descarga exitosa, conservar solo las 100 entradas más recientes del caché
- [x] 1.8 Salir con código cero e imprimir cadena vacía cuando la pista no expone `mpris:artUrl`
- [x] 1.9 Dar permiso de ejecución y verificar a mano: primera reproducción descarga, segunda consulta acierta en caché, y nada escribe en stderr

## 2. Snapshot de estado

- [x] 2.1 Añadir en `get_player_state.sh` el campo con la ruta de la carátula, obtenido del script de caché
- [x] 2.2 Comprobar que el snapshot sigue siendo JSON válido de una línea en los tres estados: con portada, descargando y sin reproductor
- [x] 2.3 Medir que el tiempo de ejecución del snapshot no crece de forma apreciable, es decir que la descarga no se coló en el camino síncrono

## 3. Widget

- [x] 3.1 Devolver a `.player-art` el `:style` con `background-image`, usando la ruta local en formato `file://`
- [x] 3.2 Dejar el estilo sin `background-image` cuando la ruta viene vacía, de modo que el panel se vea como hoy
- [ ] 3.3 Verificar que el texto sigue legible sobre portadas claras, que es para lo que existe el degradado de `.player-info`

## 4. Verificación en vivo

- [x] 4.1 Sincronizar con `./sync.sh`, recargar eww y abrir el panel sobre una pista nueva: la portada aparece en un tick, sin congelar el panel
- [ ] 4.2 Cambiar de pista con el panel abierto y comprobar que la portada se actualiza
- [x] 4.3 Volver a una pista ya escuchada y confirmar que la portada aparece de inmediato, sin descarga
- [ ] 4.4 Desconectar la red y comprobar que el panel sigue operativo, sin portada y sin una ráfaga de reintentos
- [x] 4.5 Comprobar el caché en disco: archivos con nombre de id de pista, sin `.part` huérfanos, dentro del tope

## 5. Documentación

- [x] 5.1 Documentar en `README.md` el directorio de caché, su tope y que se puede borrar sin consecuencias
