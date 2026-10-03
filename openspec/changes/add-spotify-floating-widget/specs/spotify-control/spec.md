## ADDED Requirements

### Requirement: Single control entry point

The system SHALL route all Spotify control through the single canonical script at `~/.config/sxhkd/scripts/spotify_control`, used by both keyboard shortcuts and the EWW widget. No references to alternate paths for that script SHALL remain, and no caller SHALL invoke `playerctl` directly.

#### Scenario: All keybindings use the canonical path

- **WHEN** `.config/sxhkd/sxhkdrc` is inspected for `spotify_control` invocations
- **THEN** every invocation uses the path `~/.config/sxhkd/scripts/spotify_control`
- **AND** no reference to `~/.config/sxhkd/spotify_control` remains

#### Scenario: The widget delegates instead of calling playerctl

- **WHEN** the `:onclick` handlers in `.config/eww/player/player.yuck` are inspected
- **THEN** each one invokes the canonical script
- **AND** no handler invokes `playerctl` directly

### Requirement: MPRIS playback commands

The control script SHALL accept a subcommand as its first argument and translate it into the corresponding MPRIS action against the `spotify` player using `playerctl`. Supported subcommands MUST be `playpause`, `play`, `next`, `previous`, `stop`, `seek-forward`, `seek-backward`, `shuffle` and `repeat`.

#### Scenario: Toggle playback

- **WHEN** `spotify_control playpause` runs while Spotify is playing
- **THEN** playback pauses without the Spotify window needing focus

#### Scenario: Skip track

- **WHEN** `spotify_control next` runs
- **THEN** Spotify advances to the next track in the queue

#### Scenario: Seek within the current track

- **WHEN** `spotify_control seek-forward` runs
- **THEN** the playback position advances by 8 seconds
- **AND** `seek-backward` rewinds by 8 seconds

#### Scenario: Unknown subcommand

- **WHEN** `spotify_control` runs with an unsupported subcommand
- **THEN** the script exits with a non-zero status
- **AND** writes a usage message to stderr

### Requirement: Shuffle toggle and repeat cycling

The script SHALL toggle `shuffle` between on and off. Invoked without an argument, `repeat` SHALL cycle through `None`, `Playlist` and `Track` in that order; invoked with an explicit state argument, it MUST set that state directly.

#### Scenario: Full repeat cycle

- **WHEN** `spotify_control repeat` runs three times in a row starting from `None`
- **THEN** the repeat state goes through `Playlist`, then `Track`, and back to `None`

#### Scenario: Explicit repeat state

- **WHEN** `spotify_control repeat Playlist` runs
- **THEN** the repeat state is set to `Playlist` regardless of the previous state

#### Scenario: Toggle shuffle

- **WHEN** `spotify_control shuffle` runs with shuffle disabled
- **THEN** shuffle becomes enabled

### Requirement: Playback state snapshot

The system SHALL expose playback state and metadata as a single JSON object on one line, so one `defpoll` per tick feeds the whole widget instead of one process per field. The snapshot MUST include the playback status, title, artist, shuffle state, repeat state, and the position and duration both as numeric seconds and formatted as `m:ss`. String values MUST be escaped so that titles containing quotes or backslashes keep the output parseable.

#### Scenario: Snapshot while playing

- **WHEN** the snapshot is queried while Spotify is playing
- **THEN** the output is a single line of valid JSON
- **AND** its status field is one of `Playing`, `Paused` or `Stopped`
- **AND** its title and artist fields match the current track

#### Scenario: Position and duration are comparable

- **WHEN** the snapshot is queried for a track
- **THEN** the numeric position and duration are both expressed in seconds
- **AND** their formatted counterparts are both rendered as `m:ss`

#### Scenario: Titles containing quotes

- **WHEN** the current track title contains a double quote or a backslash
- **THEN** the output is still valid, parseable JSON

### Requirement: Silent degradation without Spotify

When Spotify is not running or does not expose its MPRIS interface, the snapshot command MUST exit with status zero and report a known sentinel state, so EWW `defpoll` variables are never left in an error state. Control commands MUST exit without visible errors and without side effects.

#### Scenario: Snapshot without Spotify running

- **WHEN** the snapshot is queried and Spotify is not running
- **THEN** the output is still valid JSON with the status field set to `Offline`
- **AND** its title and artist fields are empty strings
- **AND** the exit status is zero

#### Scenario: Control command without Spotify running

- **WHEN** `spotify_control next` runs and Spotify is not running
- **THEN** the script emits no `playerctl` errors to stderr
- **AND** it neither blocks nor leaves hanging processes

### Requirement: Working media keys

Keyboard media keys SHALL control Spotify through the canonical script, independently of window focus.

#### Scenario: Media keys are bound and working

- **WHEN** the `XF86AudioPlay`, `XF86AudioStop`, `XF86AudioPrev` and `XF86AudioNext` bindings in `sxhkdrc` are inspected
- **THEN** each one invokes the canonical script with its corresponding subcommand

#### Scenario: Seek and repeat shortcuts are migrated

- **WHEN** the `super + F11`, `super + F10`, `super + Pause` and `super + Delete` bindings are inspected
- **THEN** each one invokes the canonical script instead of raw `dbus-send`
- **AND** `super + Pause` sets repeat to `Playlist` and `super + Delete` sets it to `Track`, preserving their previous behavior

#### Scenario: Control with Spotify in the background

- **WHEN** Spotify is minimized or unfocused and `XF86AudioNext` is pressed
- **THEN** Spotify skips to the next track
