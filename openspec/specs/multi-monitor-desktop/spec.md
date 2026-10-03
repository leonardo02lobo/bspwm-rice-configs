# multi-monitor-desktop

## Purpose

Garantizar que el rice esté presente en cada monitor conectado: barras de polybar en todos los monitores, reparto de escritorios (eDP con I..VI y el externo con VII..X, colocado a la derecha del laptop), gestión de conexión y desconexión en caliente, y trigger de Spotify en cada barra.

## Requirements

### Requirement: Barras de polybar en cada monitor conectado
El rice SHALL lanzar una instancia de cada barra de polybar (`workspace.ini`: `primary`; `current.ini`: `updates`, `date`, `target_to_hack`, `primary`, `principal_bar`) en cada monitor conectado y activo, con la misma geometría relativa (anchos y offsets en porcentaje respecto a ese monitor). No SHALL quedar instancias de barra asociadas a un monitor que ya no está conectado.

#### Scenario: Arranque con solo el laptop
- **WHEN** bspwm arranca con únicamente `eDP` activo
- **THEN** se lanzan las 6 barras en `eDP` y ninguna más

#### Scenario: Arranque con monitor externo conectado
- **WHEN** bspwm arranca con `eDP` y `HDMI-A-0` activos
- **THEN** se lanzan 6 barras en `eDP` y 6 barras en `HDMI-A-0`, con la misma disposición en ambos

#### Scenario: El módulo de workspaces muestra solo los escritorios de su monitor
- **WHEN** las barras están activas en ambos monitores
- **THEN** la barra de workspaces de `eDP` muestra `I..VI` y la del externo muestra `VII..X`

### Requirement: Reparto de escritorios por monitor
`eDP` SHALL tener los escritorios `I II III IV V VI` y el monitor externo SHALL tener los escritorios `VII VIII IX X`, en ese orden, de modo que el índice global de escritorio (`^1..^10`) recorra primero `eDP` y luego el externo. Ningún monitor activo SHALL quedarse con el escritorio por defecto `Desktop`. Los nombres de escritorio MUST ser únicos.

#### Scenario: Atajo hacia un escritorio del externo
- **WHEN** con el externo conectado el usuario pulsa el atajo existente de `sxhkdrc` para el escritorio `^7`
- **THEN** se enfoca el escritorio `VII` en el monitor externo

#### Scenario: Fallback de set_workspaces
- **WHEN** `set_workspaces` recibe un número inválido
- **THEN** el fallback define escritorios con nombres únicos y consecutivos en el monitor indicado, sin duplicados ni huecos

### Requirement: Conexión de un monitor en caliente
Al conectar y activar un monitor externo con la sesión ya iniciada, el rice SHALL, sin intervención manual más allá del `xrandr` del usuario: asignar al externo los escritorios `VII..X`, lanzar las barras de polybar en él y abrir el trigger de Spotify en su barra. Si los escritorios `VII..X` ya existen en `eDP` (por una desconexión previa), SHALL moverlos al externo con sus ventanas en lugar de crear escritorios nuevos.

#### Scenario: Primera conexión en la sesión
- **WHEN** el usuario activa `HDMI-A-0` con xrandr y no existen escritorios `VII..X`
- **THEN** el externo recibe `VII VIII IX X`, el escritorio `Desktop` por defecto desaparece y aparecen sus barras y su trigger de Spotify

#### Scenario: Reconexión tras desconectar
- **WHEN** el usuario reconecta el externo y `eDP` contiene `VII..X` con ventanas abiertas
- **THEN** esos escritorios vuelven al externo con sus ventanas intactas

#### Scenario: Cambio de geometría
- **WHEN** cambia la resolución o la posición de un monitor activo
- **THEN** las barras y los triggers de Spotify se relanzan con la nueva geometría

### Requirement: Posición del monitor externo
El monitor externo SHALL quedar colocado inmediatamente a la derecha de `eDP` (su borde izquierdo en el borde derecho de `eDP`), de modo que el puntero pase de `eDP` al externo moviéndose hacia la derecha. El rice SHALL corregir la posición al arrancar y en cada conexión o cambio de geometría, y SHALL NOT volver a llamar a xrandr cuando el externo ya está en su sitio, para no generar eventos de geometría en bucle.

#### Scenario: Reconectar con el externo en otra posición
- **WHEN** el usuario activa `HDMI-A-0` con xrandr y X lo coloca a la izquierda de `eDP` o encima de él
- **THEN** el externo queda reposicionado a la derecha de `eDP`, y sus barras y su trigger se colocan en la nueva posición

#### Scenario: Externo ya en su sitio
- **WHEN** se reconcilian los monitores y el externo ya está a la derecha de `eDP`
- **THEN** no se ejecuta xrandr y no se dispara ninguna reconciliación adicional

### Requirement: Desconexión de un monitor en caliente
Al desconectar o desactivar el monitor externo, sus escritorios y ventanas SHALL fusionarse en `eDP` (bspwm con `remove_unplugged_monitors` activado), sin que ninguna ventana quede en un monitor inaccesible, y las barras y el trigger de Spotify de ese monitor SHALL desaparecer.

#### Scenario: Desenchufar con ventanas abiertas en el externo
- **WHEN** el usuario desconecta `HDMI-A-0` con ventanas abiertas en `VIII`
- **THEN** `eDP` pasa a tener `I..X`, las ventanas de `VIII` siguen accesibles en `eDP`, y solo quedan las barras de `eDP`

### Requirement: Trigger de Spotify en cada barra
Cada monitor activo SHALL mostrar el icono trigger de Spotify en el hueco de su `principal_bar`. Al posar el puntero sobre el trigger de un monitor, el panel de Spotify SHALL desplegarse en ese mismo monitor, bajo ese trigger. Solo SHALL haber un panel abierto a la vez, y al retirar el puntero SHALL colapsarse y cerrarse igual que hoy.

#### Scenario: Hover en el trigger del externo
- **WHEN** el puntero se posa sobre el trigger de Spotify de la barra de `HDMI-A-0`
- **THEN** el panel se despliega en `HDMI-A-0` bajo ese trigger, y no aparece ningún panel en `eDP`

#### Scenario: Pasar de un trigger al otro
- **WHEN** el panel está abierto en un monitor y el puntero se va al trigger del otro monitor
- **THEN** el panel del primer monitor se cierra y se abre en el monitor del segundo trigger
