## ADDED Requirements

### Requirement: Permanent trigger in the bar

The system SHALL display a Spotify icon as an always-present EWW window positioned over the free gap in the Polybar top bar, opened at session start. Its position MUST be derived from the measured geometry of the running bar windows, not from a Polybar configuration file.

#### Scenario: Icon present after login

- **WHEN** the session starts
- **THEN** the Spotify icon is visible in the bar's free gap

#### Scenario: The icon does not cover bar modules

- **WHEN** the icon window is placed
- **THEN** it falls within the gap between the neighbouring modules
- **AND** clicks on those modules still reach Polybar

#### Scenario: Daemon not ready at startup

- **WHEN** the session opens the window before the EWW daemon is accepting requests
- **THEN** the window still ends up open, rather than silently failing

### Requirement: Panel reveals on hover

Pointing at the trigger SHALL reveal the player panel with a downward sliding transition, and moving the pointer away SHALL hide it again.

#### Scenario: Pointer enters the trigger

- **WHEN** the pointer moves onto the icon
- **THEN** the panel slides down into view

#### Scenario: Pointer leaves the area

- **WHEN** the pointer moves off the trigger and the revealed panel
- **THEN** the panel slides back up and is hidden

#### Scenario: Hidden panel intercepts nothing

- **WHEN** the panel is hidden
- **THEN** no window of it remains over the desktop swallowing clicks meant for what is underneath

### Requirement: The pointer can reach the panel

Moving the pointer from the icon into the revealed panel MUST NOT hide it. Since the icon and the panel are separate windows — eww reserves the revealer child's width even when collapsed, which would make a combined window wide enough to cover the neighbouring bar module — both MUST listen for hover and share a single pending-hide timer, so entering either one cancels a hide armed by leaving the other.

#### Scenario: Moving from icon to panel

- **WHEN** the pointer travels from the icon down into the revealed panel
- **THEN** the panel stays open

#### Scenario: Using a control in the revealed panel

- **WHEN** the pointer moves onto a button inside the revealed panel and clicks it
- **THEN** the panel stays open
- **AND** the control performs its action

### Requirement: Revealing is idempotent

Pointing at an already-revealed panel MUST NOT re-issue the reveal. Opening a window that eww already has open destroys and recreates it, which fires a fresh enter event under a stationary pointer and re-enters this path — a loop that feeds itself for as long as the pointer rests there.

#### Scenario: Pointer rests on the revealed panel

- **WHEN** the pointer sits still over the revealed panel for a second
- **THEN** no further reveal work is performed
- **AND** the panel's window is not recreated

### Requirement: Grace delay before hiding

Hiding MUST be deferred by a short delay, after which it proceeds only if the pointer is no longer over the trigger, the panel, or the strip between them. Deciding by pointer position rather than by cancelling the pending hide is required because the trigger and the panel are separate windows: leaving one and entering the other fires both handlers in the same millisecond, with no ordering guarantee between them.

#### Scenario: Pointer crosses onto a child widget

- **WHEN** a leave event fires because the pointer moved onto a button inside the panel
- **THEN** the panel does not hide, because the pointer is back inside before the delay elapses

#### Scenario: Travelling from the icon to the panel

- **WHEN** the pointer leaves the icon and arrives on the panel within the delay
- **THEN** the panel stays revealed, because the pointer is over it when the hide comes due

#### Scenario: Pausing in the strip between the windows

- **WHEN** the pointer stops in the bare screen between the icon and the panel
- **THEN** the panel stays revealed

### Requirement: Coexistence with the keyboard shortcut

The hover window and the `music` window opened by `super + ctrl + s` MUST work independently, sharing the same player widget definition and the same polled state.

#### Scenario: Shortcut still works

- **WHEN** `super + ctrl + s` is pressed
- **THEN** the `music` window toggles exactly as before, unaffected by the hover window

#### Scenario: Single source of state

- **WHEN** both windows are visible at once
- **THEN** both show the same track information
- **AND** the state is produced by one poll, not one per window
