## ADDED Requirements

### Requirement: Pantalla de reposo previa al bloqueo
El rice SHALL mostrar una pantalla de reposo a pantalla completa tras un periodo de inactividad menor que el del bloqueo, de modo que aparezca antes y ceda el paso al bloqueo cuando este llegue.

#### Scenario: Inactividad corta
- **WHEN** se agota el tramo de reposo pero aún no el de bloqueo
- **THEN** se muestra la pantalla de reposo y la sesión sigue desbloqueada

#### Scenario: La inactividad continúa hasta el bloqueo
- **WHEN** se agota también el tramo de bloqueo
- **THEN** la pantalla de reposo desaparece y queda la pantalla de bloqueo

### Requirement: Contenido de la pantalla de reposo
La pantalla de reposo SHALL mostrar la hora y, cuando haya reproducción activa, el título, el artista y la carátula de lo que suena, reutilizando el estado que ya publica el reproductor.

#### Scenario: Con música sonando
- **WHEN** la pantalla de reposo aparece mientras hay una pista en reproducción
- **THEN** muestra la hora junto al título, el artista y la carátula de esa pista

#### Scenario: Sin reproductor activo
- **WHEN** la pantalla de reposo aparece sin reproducción
- **THEN** muestra la hora sin dejar huecos vacíos ni datos de una sesión anterior

### Requirement: Presencia en cada monitor conectado
La pantalla de reposo SHALL cubrir cada salida conectada en el momento de aparecer, con una ventana propia por salida.

#### Scenario: Laptop y monitor externo
- **WHEN** la pantalla de reposo aparece con dos monitores conectados
- **THEN** ambas pantallas la muestran, y ninguna queda con el escritorio a la vista

#### Scenario: Solo el laptop
- **WHEN** la pantalla de reposo aparece con un único monitor
- **THEN** se abre una sola ventana, sin dejar ventanas sobrantes

### Requirement: Desaparición sin rastro
La pantalla de reposo SHALL cerrarse por completo cuando vuelve la actividad o cuando arranca el bloqueo, sin dejar ventanas abiertas sobre la sesión.

#### Scenario: Vuelta de la actividad
- **WHEN** se mueve el ratón o se pulsa una tecla con la pantalla de reposo visible
- **THEN** desaparece y el escritorio queda utilizable de inmediato

#### Scenario: Relevo por el bloqueo
- **WHEN** el bloqueo arranca con la pantalla de reposo visible
- **THEN** esta se cierra en lugar de quedar por debajo o por encima

#### Scenario: Ciclos repetidos
- **WHEN** la sesión entra y sale del reposo varias veces
- **THEN** no se acumulan ventanas ni procesos de reposo

### Requirement: La pantalla de reposo no protege la sesión
La pantalla de reposo SHALL ser puramente decorativa: NO SHALL considerarse una medida de protección, y su presencia NO SHALL retrasar ni sustituir al bloqueo.

#### Scenario: Cierre de la capa decorativa
- **WHEN** la pantalla de reposo se cierra por cualquier medio antes de que llegue el bloqueo
- **THEN** el bloqueo sigue llegando en su momento
