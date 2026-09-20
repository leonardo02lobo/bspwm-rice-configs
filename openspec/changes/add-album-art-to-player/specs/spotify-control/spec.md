## ADDED Requirements

### Requirement: Album art path in the state snapshot

The playback state snapshot SHALL include the local filesystem path of the current track's cached album art, or an empty string when no art is available yet. Producing that field MUST NOT make the snapshot wait on the network.

#### Scenario: Snapshot with art already cached

- **WHEN** the snapshot is queried and the current track's art is cached
- **THEN** the output includes the local path to that file
- **AND** the output is still a single line of valid JSON

#### Scenario: Snapshot while art is still downloading

- **WHEN** the snapshot is queried and the art has not been downloaded yet
- **THEN** the art field is an empty string
- **AND** the snapshot returns without waiting for the download

#### Scenario: Snapshot without Spotify running

- **WHEN** the snapshot is queried and Spotify is not running
- **THEN** the art field is an empty string
- **AND** the exit status is zero
