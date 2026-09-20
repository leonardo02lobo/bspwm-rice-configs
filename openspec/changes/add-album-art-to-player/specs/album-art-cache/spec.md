## ADDED Requirements

### Requirement: Album art cached by track identity

The system SHALL cache album art on disk under a filename derived from the track's `mpris:trackid`, so that a track already heard never triggers a second download. The cache directory MUST be `${XDG_CACHE_HOME:-$HOME/.cache}/eww/player-art`.

#### Scenario: First play of a track

- **WHEN** art is requested for a track with no cached file
- **THEN** a download of that track's `mpris:artUrl` is started
- **AND** the resulting file is named after the track's id

#### Scenario: Returning to a track already cached

- **WHEN** art is requested for a track whose file is already cached
- **THEN** no network request is made
- **AND** the path to the cached file is returned

#### Scenario: Track id is used as a safe filename

- **WHEN** the track id arrives as a D-Bus path such as `/com/spotify/track/0QvmWZeyks41359inOe41X`
- **THEN** the cache filename derives from the final segment only

### Requirement: Downloads never block the caller

The art lookup MUST return immediately. When the file is absent it MUST start the download in the background and report that no art is available yet, rather than waiting for the network.

#### Scenario: Lookup while the file is missing

- **WHEN** art is requested for a track that is not cached
- **THEN** the command returns without waiting for the download
- **AND** it reports an empty path

#### Scenario: The next lookup finds the art

- **WHEN** a lookup is repeated after the background download has finished
- **THEN** it reports the path to the cached file

#### Scenario: No duplicate downloads for the same track

- **WHEN** a lookup runs for a track whose download is already in flight
- **THEN** no second download is started

### Requirement: Atomic cache writes

Art MUST be downloaded to a temporary file and moved into place only once complete, so that no reader can ever observe a partially written image.

#### Scenario: Reader during an in-flight download

- **WHEN** the cache is inspected while a download is in progress
- **THEN** the final path either does not exist or holds a complete image
- **AND** a partial file is never exposed under the final name

#### Scenario: Failed download leaves no partial file

- **WHEN** a download fails or is interrupted
- **THEN** no file remains under the final path

#### Scenario: Stale in-flight marker

- **WHEN** a download marker is older than one minute, meaning the process that created it died
- **THEN** it is treated as stale and a new download may start

### Requirement: Backoff after a failed download

After a failed download, the system MUST record the failure and refrain from retrying that track for at least 60 seconds, so that an unreachable network does not produce one request per poll.

#### Scenario: Repeated lookups while offline

- **WHEN** the network is unreachable and lookups run once per second for a minute
- **THEN** at most one download attempt is made in that window

#### Scenario: Recovery after the backoff window

- **WHEN** the backoff window has elapsed and art is requested again
- **THEN** a new download attempt is made

### Requirement: Bounded cache size

After a successful download, the cache MUST be trimmed so that only the most recently used entries are retained, keeping the directory bounded without an expiry policy.

#### Scenario: Cache beyond the retention limit

- **WHEN** a download completes and the cache holds more entries than the limit
- **THEN** the oldest entries are removed
- **AND** the entry just downloaded is retained

### Requirement: Tracks without art

A track that exposes no `mpris:artUrl` — a local file or a podcast, for instance — MUST be handled like any other absence of art, with no error and no repeated attempts.

#### Scenario: Track with no art URL

- **WHEN** art is requested for a track whose metadata has no `mpris:artUrl`
- **THEN** the command reports an empty path and exits with status zero
- **AND** no download is attempted
