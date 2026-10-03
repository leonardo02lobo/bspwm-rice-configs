#!/usr/bin/env bash
# Resolves the local path of a track's album art, fetching it in the background
# when it is missing. Prints the path, or nothing when there is no art yet.
#
#   get_album_art.sh <mpris:trackid> <mpris:artUrl>
#
# Never waits on the network. The caller polls once a second and a cover takes
# roughly 0.85s to download, so fetching inline would freeze the panel on every
# track change. A miss starts the download and prints nothing; the next poll
# finds the file.
#
# Cached by track id rather than by age: a track's cover never changes, so
# there is nothing to invalidate and a replay is always a hit.

readonly CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/eww/player-art"
readonly KEEP=100        # entries retained, at roughly 60KB per cover
readonly RETRY_AFTER=60  # seconds before retrying a track whose download failed
readonly STALE_AFTER=60  # a .part older than this means the downloader died

now() { date +%s; }
older_than() { (( $(now) - $(stat -c %Y "$1" 2>/dev/null || now) >= $2 )); }

trackid="${1:-}"
arturl="${2:-}"

# Local files and podcasts often carry no art; that is not an error.
[[ -n "$trackid" && -n "$arturl" ]] || exit 0

id="${trackid##*/}"
[[ "$id" =~ ^[A-Za-z0-9]+$ ]] || exit 0

mkdir -p "$CACHE" 2>/dev/null || exit 0

file="$CACHE/$id.jpg"
part="$CACHE/$id.part"
fail="$CACHE/$id.fail"

if [[ -f "$file" ]]; then
  touch "$file"  # mtime is the recency the trim policy sorts on
  echo "$file"
  exit 0
fi

# A download is already in flight, or one failed recently. Either way, wait.
[[ -f "$part" ]] && ! older_than "$part" "$STALE_AFTER" && exit 0
[[ -f "$fail" ]] && ! older_than "$fail" "$RETRY_AFTER" && exit 0

(
  if curl -sfL --max-time 15 -o "$part" "$arturl"; then
    # Atomic within the same filesystem: a reader sees a whole image or none.
    mv -f "$part" "$file"
    rm -f "$fail"
    ls -t "$CACHE"/*.jpg 2>/dev/null | tail -n +$(( KEEP + 1 )) | xargs -r rm -f
  else
    rm -f "$part"
    touch "$fail"
  fi
) >/dev/null 2>&1 &

exit 0
