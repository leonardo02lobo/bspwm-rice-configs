## ADDED Requirements

### Requirement: Bloqueo automático por inactividad
La sesión SHALL bloquearse automáticamente tras un periodo de inactividad configurado, exigiendo la contraseña del usuario para volver. El bloqueo SHALL cubrir todos los monitores conectados.

#### Scenario: Inactividad prolongada
- **WHEN** no hay actividad de teclado ni de puntero durante el tramo configurado
- **THEN** la sesión queda bloqueada
- **AND** cualquier entrada posterior solo sirve para introducir la contraseña

#### Scenario: Dos monitores conectados
- **WHEN** el bloqueo se activa con el laptop y un monitor externo conectados
- **THEN** ninguna de las dos pantallas muestra contenido de la sesión

### Requirement: Bloqueo antes de dormir
La sesión SHALL quedar bloqueada antes de que el equipo entre en suspensión, tanto si la suspensión la provoca el atajo de teclado como si la provoca el cierre de la tapa.

#### Scenario: Suspensión por atajo
- **WHEN** se pulsa el atajo que ejecuta `systemctl suspend`
- **THEN** el equipo despierta mostrando la pantalla de bloqueo

#### Scenario: Cierre de tapa
- **WHEN** se cierra la tapa y el equipo suspende
- **THEN** al abrirla la sesión está bloqueada

### Requirement: Un único bloqueador
SHALL existir un solo mecanismo de bloqueo activo en la sesión. Cualquier bloqueador alternativo instalado en el sistema SHALL quedar desactivado, incluidos los que puedan arrancarse solos por autoarranque XDG o por activación de D-Bus.

#### Scenario: Bloqueador alternativo presente en el sistema
- **WHEN** una aplicación invoca la interfaz D-Bus del bloqueador alternativo
- **THEN** ese bloqueador no toma el control del teclado ni muestra su propia pantalla

#### Scenario: Arranque de sesión
- **WHEN** arranca la sesión
- **THEN** solo el bloqueador del rice queda en ejecución

### Requirement: Bloqueo bajo demanda
SHALL existir un atajo de teclado que bloquee la sesión de inmediato, sin esperar al temporizador.

#### Scenario: Bloqueo manual
- **WHEN** se pulsa el atajo de bloqueo
- **THEN** la sesión queda bloqueada al instante

### Requirement: La pantalla de bloqueo no revela la sesión
La pantalla de bloqueo NO SHALL mostrar, ni siquiera transformado, el contenido que había en pantalla al bloquear. El fondo SHALL ser una imagen independiente de la sesión.

#### Scenario: Bloqueo con ventanas abiertas
- **WHEN** la sesión se bloquea con documentos o conversaciones a la vista
- **THEN** la pantalla de bloqueo no permite distinguir qué había abierto

### Requirement: Inhibición manual del bloqueo
SHALL existir un atajo que suspenda el bloqueo automático mientras esté activo, y un indicador visible de ese estado. La inhibición SHALL poder revertirse con el mismo atajo.

#### Scenario: Ver algo sin tocar el teclado
- **WHEN** la inhibición está activa y transcurre el tiempo de inactividad
- **THEN** la sesión no se bloquea ni se apaga la pantalla

#### Scenario: Estado visible
- **WHEN** la inhibición está activa
- **THEN** un indicador lo refleja, de modo que no quede activada sin saberlo

#### Scenario: Volver al comportamiento normal
- **WHEN** se pulsa de nuevo el atajo
- **THEN** el bloqueo automático vuelve a estar operativo

### Requirement: El apagado de pantalla llega después del bloqueo
El apagado del panel por DPMS SHALL ocurrir después de que la sesión esté bloqueada, nunca antes.

#### Scenario: Secuencia de inactividad completa
- **WHEN** el equipo queda inactivo hasta agotar todos los tramos
- **THEN** la sesión se bloquea primero y el panel se apaga después
