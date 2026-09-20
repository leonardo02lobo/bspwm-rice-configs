## ADDED Requirements

### Requirement: Album art shown behind the track information

The panel SHALL display the current track's album art as the background of its art container, with the existing gradient overlay keeping the title, artist and controls legible on top of it.

#### Scenario: Art available

- **WHEN** the panel is open and the current track's art is cached
- **THEN** the art container shows that image, scaled to cover its area
- **AND** the title and artist remain legible over it

#### Scenario: Art changes with the track

- **WHEN** the track changes to one whose art is already cached
- **THEN** the panel shows the new art without restarting or reopening

### Requirement: The panel is unchanged when there is no art

When no art path is available — the download is still in flight, the network is unreachable, the track exposes none, or Spotify is not running — the panel MUST render exactly as it does today, with its flat background and no error state.

#### Scenario: Art still downloading

- **WHEN** the panel is open on a track whose art has not arrived yet
- **THEN** the art container keeps its plain background
- **AND** no placeholder or error is displayed

#### Scenario: Art arrives while the panel is open

- **WHEN** the download completes while the panel is open
- **THEN** the art appears on the next poll without user interaction
