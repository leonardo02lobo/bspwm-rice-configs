# desktop-window-transitions

## Purpose

TBD - describe why this capability exists and what value it delivers to users.

## Requirements

### Requirement: Transición de escritorio como crossfade uniforme
Al cambiar de escritorio en bspwm, las ventanas del escritorio saliente y entrante SHALL animar únicamente su opacidad (sin escalado ni desplazamiento), con una duración corta (~0.13s), de modo que múltiples ventanas cambien de estado de forma visualmente uniforme en lugar de escalar de forma independiente y desincronizada.

#### Scenario: Cambiar de escritorio con una sola ventana
- **WHEN** el usuario cambia de escritorio (`bspc desktop -f {prev,next}.local`) y el escritorio destino tiene una única ventana
- **THEN** la ventana aparece mediante un fade de opacidad corto, sin efecto de escalado

#### Scenario: Cambiar de escritorio con múltiples ventanas
- **WHEN** el usuario cambia de escritorio y tanto el escritorio de origen como el destino tienen varias ventanas
- **THEN** todas las ventanas involucradas animan opacidad con el mismo timing, sin que se perciba un escalado individual desincronizado por ventana

### Requirement: Animación de apertura/cierre de aplicaciones diferenciada del cambio de escritorio
Los eventos de apertura (`open`) y cierre (`close`) de una ventana SHALL usar una animación de escalado + opacidad ("genie") independiente del bloque de animación usado para cambio de escritorio (`hide`/`show`), con curvas de aceleración asimétricas: `open` decelera (ease-out marcado) y `close` acelera (ease-in) hacia el final de la animación.

#### Scenario: Lanzar una aplicación nueva
- **WHEN** se abre una ventana nueva (evento `open`)
- **THEN** la ventana anima escala 0.85→1 y opacidad 0→1 con una curva de deceleración marcada, independientemente del bloque de animación de cambio de escritorio

#### Scenario: Cerrar una aplicación
- **WHEN** se cierra una ventana (evento `close`)
- **THEN** la ventana anima escala 1→0.85 y opacidad 1→0 con una curva de aceleración hacia el final, distinta de la curva usada en `open`

### Requirement: Foco sigue al puntero
bspwm SHALL tener `focus_follows_pointer` activado, de modo que la ventana bajo el puntero reciba el foco al entrar en ella, sin necesidad de click. Un click sobre una ventana SHALL seguir enfocándola. Las ventanas no gestionadas por bspwm (barras de polybar y widgets eww con `wm-ignore`) MUST NOT recibir foco por hover.

#### Scenario: Mover el mouse sobre otra ventana
- **WHEN** el puntero entra en una ventana gestionada distinta a la enfocada, sin hacer click
- **THEN** esa ventana recibe el foco

#### Scenario: Cruzar a otro monitor
- **WHEN** el puntero pasa de una ventana en `eDP` a una ventana en el monitor externo
- **THEN** la ventana del monitor externo recibe el foco y ese monitor pasa a ser el monitor enfocado

#### Scenario: Pasar sobre la barra o un widget
- **WHEN** el puntero se posa sobre una barra de polybar o un widget eww
- **THEN** el foco permanece en la última ventana enfocada

#### Scenario: Hacer click sobre otra ventana
- **WHEN** el usuario hace click sobre una ventana distinta a la enfocada
- **THEN** esa ventana recibe el foco
