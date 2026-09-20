## 1. Preparar el widget para reutilizarse

- [x] 1.1 Añadir a `defwidget player` un parámetro que controle si se renderiza el botón de cerrar
- [x] 1.2 Pasar el parámetro activado desde la ventana `music`, y verificar que sigue comportándose igual que hoy
- [x] 1.3 Comprobar con `eww reload` que no hay errores y que el atajo `super + ctrl + s` sigue funcionando

## 2. Estado del hover

- [x] 2.1 Añadir en `player.yuck` la variable de estado que gobierna el `revealer`
- [x] 2.2 Crear `.config/bspwm/scripts/player/hover_player.sh`, que recibe `show` u `hide` y aplica el estado con `eww update`, siempre con `-c` explícito
- [x] 2.3 Implementar el retardo de gracia antes de replegar
- [x] 2.4 Hacer `show` idempotente: `eww open` sobre una ventana abierta la recrea, lo que emite un `enter` nuevo bajo el puntero quieto y realimenta el hover (36 invocaciones por gesto, medidas con `xdotool`; 4 tras la guarda)
- [x] 2.6 Decidir el repliegue consultando la posición del puntero en vez de cancelar el temporizador: el pid y el token de generación pierden la misma carrera entre las dos ventanas, y el panel se colapsaba 0.3s después de alcanzarlo
- [x] 2.7 Cubrir con margen el corredor de 27px entre el icono y el panel, para que detenerse a mitad de camino no cierre el panel
- [x] 2.5 Dar permiso de ejecución y verificar a mano, alternando `show`/`hide` y comprobando con `eww get` que el estado cambia y que no quedan procesos huérfanos

## 3. Ventana del disparador

- [x] 3.1 Definir dos ventanas, cada una con su `eventbox`, compartiendo un único repliegue pendiente: eww reserva el ancho del hijo del `revealer` aunque esté replegado, así que una sola ventana medía 365px en reposo y tapaba `primary_bar`
- [x] 3.2 Poner dentro del `revealer` el `(player)` con el botón de cerrar desactivado, y `:transition "slidedown"`
- [x] 3.3 Cablear `:onhover` y `:onhoverlost` al script de hover
- [x] 3.4 Configurar la ventana como overlay, sin foco y sin gestión del WM, para que quede sobre la barra sin robar el foco
- [x] 3.5 Anclar ambas arriba a la derecha con el mismo desplazamiento, de modo que el icono caiga en el hueco medido (`x 1078..1242`) y el panel cuelgue bajo él creciendo hacia la izquierda
- [x] 3.6 Cerrar la ventana del panel tras la animación de repliegue: eww no encoge el toplevel, y una ventana invisible de 365x176 sin forma de entrada se traga los clics de lo que hay debajo

## 4. Estilo

- [x] 4.1 Dar estilo al icono en `player.scss` para que encaje con el aspecto de los módulos vecinos de la barra
- [x] 4.2 Ajustar el tamaño de la ventana replegada para que el icono quede centrado en el hueco y alineado verticalmente con la barra

## 5. Arranque de sesión

- [x] 5.1 Abrir la ventana del disparador desde `bspwmrc`, junto al resto de daemons, con `-c` explícito para no hablarle al daemon de `display-manager`
- [x] 5.2 Tolerar que el daemon de eww aún no esté listo en ese momento

## 6. Verificación en vivo

- [x] 6.1 Medir con `xwininfo` que la ventana replegada cae dentro del hueco y no se solapa con `primary_bar` ni con `updates`
- [x] 6.2 Verificar el gesto completo con `xdotool`: entrar al icono, bajar al panel, recorrer los botones y hacer clic — el panel permanece abierto en todo momento y se cierra solo al salir
- [x] 6.3 Verificar que al salir el ratón el panel se repliega, y que entrar y salir repetidamente no deja temporizadores colgados
- [x] 6.4 Verificar que `super + ctrl + s` sigue abriendo su ventana con normalidad, con el disparador presente
- [ ] 6.5 Reiniciar la sesión y comprobar que el icono aparece solo
- [ ] 6.6 Ajustar el retardo de gracia según se sienta en uso, partiendo de 300ms

## 7. Documentación

- [x] 7.1 Documentar en `README.md` el indicador, su comportamiento por hover y que su posición depende del hueco medido en la barra
