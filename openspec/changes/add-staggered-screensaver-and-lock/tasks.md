## 1. Preparar el terreno

- [ ] 1.1 Instalar `xss-lock` (`sudo apt install xss-lock`)
- [ ] 1.2 Desactivar `xfce4-screensaver`: su autoarranque en `/etc/xdg/autostart/` y su activación por D-Bus, de modo que no pueda despertarlo una aplicación
- [ ] 1.3 Abrir una sesión en otro TTY como salida de emergencia antes de probar ningún bloqueo

## 2. Bloqueo, antes de automatizar nada

- [x] 2.1 Crear `.config/bspwm/scripts/idle/lock.sh` invocando `i3lock` (que es `i3lock-color`) con el fondo de escritorio, sin captura de pantalla, y con reloj y anillo nativos
- [x] 2.2 Elegir el fondo del bloqueo entre los wallpapers del rice, escalado a la resolución del panel
- [ ] 2.3 Probar el script a mano y confirmar que pide contraseña y que vuelve a la sesión correctamente
- [ ] 2.4 Verificar que con dos monitores conectados ninguna pantalla deja ver la sesión
- [x] 2.5 Añadir el atajo de bloqueo inmediato en `sxhkdrc` y comprobarlo

## 3. Medir los tiempos de xss-lock

- [ ] 3.1 Arrancar `xss-lock` a mano con un notificador de prueba que solo registre la hora, y con valores cortos de `xset s`
- [ ] 3.2 Cronometrar cuándo entra el notificador y cuándo el bloqueador, y anotar cómo se traducen `timeout` y `cycle` de `xset s`
- [ ] 3.3 Dejar anotada la equivalencia medida en el propio script, para no volver a deducirla

## 4. Cobertura de suspensión y tapa

- [ ] 4.1 Verificar que con `xss-lock` activo, `super + F12` despierta mostrando el bloqueo
- [ ] 4.2 Verificar lo mismo cerrando y abriendo la tapa
- [ ] 4.3 Confirmar que no hizo falta tocar `logind.conf`

## 5. Pantalla de reposo

- [x] 5.1 Crear `.config/eww/screensaver/screensaver.yuck` y `.scss` con reloj y, cuando haya reproducción, título, artista y carátula, reutilizando `get_player_state.sh`
- [x] 5.2 Resolver el estado sin reproductor sin dejar huecos vacíos ni datos de una sesión anterior
- [x] 5.3 Incluirlos en `eww.yuck` y `eww.scss`
- [x] 5.4 Crear `.config/bspwm/scripts/idle/screensaver.sh`, que enumera las salidas conectadas con `xrandr` y abre una ventana por cada una con `--screen`
- [x] 5.5 Añadir la trampa de `SIGTERM` que cierra todas las ventanas al terminar: sin ella quedan ventanas a pantalla completa tapando la sesión
- [x] 5.6 Probar el script a mano, lanzándolo y matándolo, y comprobar que no deja ninguna ventana ni proceso

## 6. Escalonado completo

- [ ] 6.1 Fijar en `bspwmrc` los tiempos de `xset s` y `xset dpms` según lo medido, con el reposo antes del bloqueo y DPMS después
- [ ] 6.2 Arrancar `xss-lock` desde `bspwmrc` con el notificador y el bloqueador definitivos
- [ ] 6.3 Verificar la secuencia completa dejando el equipo quieto: reposo, bloqueo, apagado de panel
- [ ] 6.4 Verificar que volver de la actividad durante el reposo deja el escritorio utilizable al instante
- [ ] 6.5 Entrar y salir del reposo varias veces seguidas y comprobar que no se acumulan ventanas ni procesos

## 7. Inhibición

- [x] 7.1 Crear `.config/bspwm/scripts/idle/inhibit.sh`, que alterna la inhibición y expone su estado
- [x] 7.2 Añadir el atajo en `sxhkdrc`
- [ ] 7.3 Añadir el indicador en Polybar — **fuera del repo**, edición manual en `~/.config/polybar/`
- [ ] 7.4 Verificar que con la inhibición activa no se bloquea ni se apaga la pantalla, y que al desactivarla vuelve a hacerlo
- [ ] 7.5 Comprobar el caso de `mpv`, que suspende el temporizador de X por su cuenta y debería funcionar sin tocar nada

## 8. Documentación

- [x] 8.1 Documentar en `README.md` los tres tramos, los atajos y la dependencia `xss-lock`
- [x] 8.2 Documentar que ver vídeo en el navegador no inhibe el bloqueo, porque nadie atiende `org.freedesktop.ScreenSaver`, y que el atajo manual es la salida
- [x] 8.3 Documentar la desactivación de `xfce4-screensaver` y el indicador de Polybar como pasos manuales fuera del repo
- [ ] 8.4 Copiar al repo lo que se haya editado en `~/.config`, que es la fuente de verdad
