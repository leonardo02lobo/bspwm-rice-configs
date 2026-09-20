## ADDED Requirements

### Requirement: Optional close button

The player widget SHALL accept a parameter controlling whether its close button is rendered, so the same definition serves both a window closed by a button and one governed by hover.

#### Scenario: Window opened by the shortcut

- **WHEN** the `music` window renders the player widget
- **THEN** the close button is shown
- **AND** it closes that window

#### Scenario: Window governed by hover

- **WHEN** the hover window renders the player widget
- **THEN** no close button is shown, since the panel hides when the pointer leaves

#### Scenario: One definition, two windows

- **WHEN** both windows are open
- **THEN** both render the same widget definition, with no duplicated copy of the panel markup
