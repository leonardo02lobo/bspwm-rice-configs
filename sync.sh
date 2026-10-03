#!/usr/bin/env bash
# Copies this repo's dotfiles into ~/.config.
#
# ~/.config holds real copies, not symlinks, so editing the repo has no effect
# until this runs. That gap is how the live config silently drifted ahead of
# git: widgets and scripts existed on the machine for months without ever being
# committed. Run --check before editing to see whether the two sides agree.
#
#   ./sync.sh          copy repo -> ~/.config
#   ./sync.sh --check  list differences and exit non-zero, writing nothing

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.config"
DEST="$HOME/.config"

check=false
[[ "${1:-}" == "--check" ]] && check=true

differences=0

while IFS= read -r -d '' file; do
  rel="${file#"$SRC"/}"
  target="$DEST/$rel"

  if [[ ! -e "$target" ]]; then
    echo "falta en el sistema:  $rel"
  elif ! cmp -s "$file" "$target"; then
    echo "difiere:              $rel"
  else
    continue
  fi

  differences=$(( differences + 1 ))
  if ! $check; then
    mkdir -p "$(dirname "$target")"
    cp -a "$file" "$target"
  fi
done < <(find "$SRC" -type f -print0)

if $check; then
  if (( differences == 0 )); then
    echo "repo y ~/.config coinciden"
    exit 0
  fi
  echo "$differences archivo(s) con diferencias"
  exit 1
fi

if (( differences == 0 )); then
  echo "nada que sincronizar"
else
  echo "sincronizados $differences archivo(s)"
  echo "recuerda recargar: pkill -USR1 -x sxhkd; eww -c ~/.config/eww reload"
fi
