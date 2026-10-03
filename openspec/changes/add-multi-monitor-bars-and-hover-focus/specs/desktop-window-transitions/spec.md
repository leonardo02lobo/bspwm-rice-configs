## ADDED Requirements

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

## REMOVED Requirements

### Requirement: Foco por click, no por hover
**Reason**: el usuario prefiere el foco por hover tras probar el click-to-focus, y encaja mejor con el flujo de dos monitores introducido en este change (el foco sigue al puntero al cruzar de pantalla).
**Migration**: sustituido por el requisito "Foco sigue al puntero"; `bspc config focus_follows_pointer true` en `bspwmrc`. El click sigue enfocando, así que no se pierde ningún comportamiento.
