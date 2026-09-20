## ADDED Requirements

### Requirement: Working Spotify panel

The existing EWW window `music`, defined in `.config/eww/player/player.yuck`, SHALL render live playback data and expose working controls. Its dependency `playerctl` MUST be installed on the system.

#### Scenario: The panel renders real data

- **WHEN** the panel is opened while Spotify is playing
- **THEN** the track title, artist, playback state, position and duration reflect the current track
- **AND** no field is left blank because a `defpoll` command failed

#### Scenario: Dependency present

- **WHEN** `playerctl --version` runs
- **THEN** it reports an installed version

### Requirement: Correct control wiring

The panel's shuffle and repeat indicators MUST reflect the state they are labelled with, and the progress bar MUST reflect playback position rather than track duration.

#### Scenario: Shuffle and repeat are not crossed

- **WHEN** the `defpoll` definitions backing the shuffle and repeat controls are inspected
- **THEN** the shuffle variable is fed by the shuffle query and the repeat variable by the repeat query

#### Scenario: Progress bar tracks position

- **WHEN** a track is playing and halfway through
- **THEN** the progress bar sits near the middle of its range, not at the end

#### Scenario: Toggling shuffle updates the indicator

- **WHEN** the shuffle control is clicked
- **THEN** the shuffle indicator changes to the new state on the next poll
- **AND** the repeat indicator is unaffected

### Requirement: Anchoring below the Polybar bar

The window MUST anchor to the top-right corner with a fixed vertical offset of 46px, so it sits directly below Polybar's `bar/main` (42px tall plus 4px of breathing room). The offset MUST be expressed in absolute pixels, not as a percentage.

#### Scenario: Window geometry

- **WHEN** the `defwindow music` definition is inspected
- **THEN** its geometry uses `:anchor "top right"`
- **AND** its `y` coordinate is `"46px"`

#### Scenario: The panel does not overlap the bar

- **WHEN** the panel opens while the Polybar bar is visible
- **THEN** the panel's top edge sits below the bar's bottom edge, without covering it

### Requirement: Explicit monitor and daemon selection

The window MUST open on the same physical output where Polybar renders its bar (`eDP`, falling back to `HDMI-2`), specified explicitly rather than relying on the monitor X marks as `primary`. Every EWW invocation MUST name its configuration directory explicitly, since a second EWW daemon runs on this system.

#### Scenario: Single monitor connected

- **WHEN** only the internal `eDP` panel is connected and the widget is opened
- **THEN** the panel appears on `eDP`, below the bar

#### Scenario: External monitor connected with a different primary

- **WHEN** an external monitor is connected and X marks it as `primary`, while Polybar still renders on `eDP`
- **THEN** the panel appears on `eDP`, below the bar, and not on the external monitor

#### Scenario: Internal panel absent

- **WHEN** `eDP` is not connected and Polybar falls back to `HDMI-2`
- **THEN** the panel appears on `HDMI-2`

#### Scenario: The correct daemon is addressed

- **WHEN** the toggle script's EWW invocation is inspected
- **THEN** it passes the configuration directory explicitly, so the request does not reach the `display-manager` daemon

### Requirement: Toggle via keyboard shortcut

The system SHALL provide a shortcut in `sxhkdrc` that toggles the panel's visibility through a dedicated script, following the WiFi widget pattern. The EWW invocation MUST be wrapped in `timeout` to avoid hanging processes when the daemon does not answer the IPC request.

#### Scenario: Toggle visibility

- **WHEN** the shortcut is pressed while the panel is closed
- **THEN** the panel opens
- **AND** pressing it again closes the panel

#### Scenario: Guard against hung IPC

- **WHEN** the EWW daemon does not respond to the open request
- **THEN** the invocation ends via `timeout` instead of blocking indefinitely

#### Scenario: The panel stays open until explicitly closed

- **WHEN** the panel is opened
- **THEN** it does not auto-close on a timer, unlike the volume and brightness OSDs

### Requirement: Live metadata

The panel SHALL keep polling state and metadata, so it reflects track changes originating from any source, including the Spotify window itself or the media keys.

#### Scenario: Track change from outside the widget

- **WHEN** the track changes while the panel is open, either by natural progression or via a media key
- **THEN** the panel shows the new metadata within one poll interval

#### Scenario: Long titles

- **WHEN** the title or artist exceeds the panel width
- **THEN** the text is visually truncated without widening the window

### Requirement: State without Spotify running

The panel MUST open and render correctly even when Spotify is not running, indicating that state explicitly instead of showing empty fields or stale data.

#### Scenario: Opening without Spotify

- **WHEN** the panel is opened and Spotify is not running
- **THEN** the panel shows a message indicating there is no active player
- **AND** it shows no leftover metadata from a previous session

#### Scenario: Clicking controls without Spotify

- **WHEN** a control is clicked while Spotify is closed
- **THEN** the panel keeps rendering without visible errors
