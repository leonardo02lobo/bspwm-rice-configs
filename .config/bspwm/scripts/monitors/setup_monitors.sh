#!/usr/bin/env bash
# Brings every connected monitor to its expected state:
#
#   laptop panel (eDP)    desktops I..VI
#   external monitor      desktops VII..X
#   every monitor         its own polybar bars and Spotify trigger
#
# Called by bspwmrc at startup and by monitor_hotplug.sh on every monitor
# event, so it must be idempotent: it only adds, moves and reorders desktops,
# never redefines them with `bspc monitor -d`, which would drop desktops that
# hold windows on a `bspc wm -r`.
#
# Desktops are matched by name, so after an unplug (bspwm merges VII..X into
# the laptop) the next run moves them back to the external, windows included.

EWW=(eww -c "${HOME}/.config/eww")
HOVER="${HOME}/.config/bspwm/scripts/player/hover_player.sh"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/bspwm_setup_monitors.lock"

ROMANS=(I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI)
LAPTOP_RANGE=(1 6)
EXTERNAL_RANGE=(7 10)

# bspwm and the hotplug listener can both trigger a run at once.
exec 9>"${LOCK}"
flock 9

desktop_names() {
  bspc query -D -m "${1}" --names
}

# set_workspaces <monitor> <from> <to>
# Ensures desktops ROMANS[from..to] live on <monitor>, taking them from another
# monitor if they already exist there. An invalid range falls back to the
# monitor's default one rather than leaving it with no named desktops.
set_workspaces() {
  local monitor="${1}" from="${2}" to="${3}" i name

  if ! [[ "${from}" =~ ^[1-9][0-9]*$ && "${to}" =~ ^[1-9][0-9]*$ ]] ||
     (( from > to || to > ${#ROMANS[@]} )); then
    echo "Error: rango de escritorios inválido '${from}..${to}' para ${monitor}." >&2
    if [[ "${monitor}" == eDP* ]]; then
      from=${LAPTOP_RANGE[0]} to=${LAPTOP_RANGE[1]}
    else
      from=${EXTERNAL_RANGE[0]} to=${EXTERNAL_RANGE[1]}
    fi
  fi

  for (( i = from; i <= to; i++ )); do
    name="${ROMANS[i - 1]}"
    if bspc query -D -d "${name}" >/dev/null 2>&1; then
      desktop_names "${monitor}" | grep -qx "${name}" ||
        bspc desktop "${name}" -m "${monitor}"
    else
      bspc monitor "${monitor}" -a "${name}"
    fi
  done
}

# bspwm gives every new monitor a desktop called "Desktop". Its windows go to
# the monitor's first named desktop before it is removed.
drop_default_desktop() {
  local monitor="${1}" id target node

  for id in $(bspc query -D -m "${monitor}"); do
    [[ "$(bspc query -D -d "${id}" --names)" == "Desktop" ]] || continue
    target="$(desktop_names "${monitor}" | grep -vx Desktop | head -n1)"
    [[ -n "${target}" ]] || continue
    for node in $(bspc query -N -d "${id}" -n .window); do
      bspc node "${node}" -d "${target}"
    done
    bspc desktop "${id}" -r
  done
}

# Keeps desktops in ROMANS order, so the global index ^N that sxhkd uses
# walks the laptop first and then the external.
reorder_desktops() {
  local monitor="${1}" name ordered=()

  for name in "${ROMANS[@]}"; do
    desktop_names "${monitor}" | grep -qx "${name}" && ordered+=("${name}")
  done
  while read -r name; do
    [[ " ${ROMANS[*]} " == *" ${name} "* ]] || ordered+=("${name}")
  done < <(desktop_names "${monitor}")

  bspc monitor "${monitor}" -o "${ordered[@]}"
}

setup_desktops() {
  local monitors laptop external

  mapfile -t monitors < <(bspc query -M --names)
  laptop="$(printf '%s\n' "${monitors[@]}" | grep -m1 '^eDP')"
  # Lid closed with the panel off: the first monitor plays the laptop role.
  laptop="${laptop:-${monitors[0]}}"
  external="$(printf '%s\n' "${monitors[@]}" | grep -vx "${laptop}" | head -n1)"

  set_workspaces "${laptop}" "${LAPTOP_RANGE[@]}"
  drop_default_desktop "${laptop}"

  if [[ -n "${external}" ]]; then
    set_workspaces "${external}" "${EXTERNAL_RANGE[@]}"
    drop_default_desktop "${external}"
    reorder_desktops "${external}"
    bspc wm -O "${laptop}" "${external}"
  fi

  reorder_desktops "${laptop}"
}

# One trigger per monitor, each sitting in its own principal_bar. Stale ones,
# such as those of an unplugged monitor, are closed first, and so is the panel.
setup_player_triggers() {
  local monitor id

  # The daemon is not accepting requests yet this early in the session.
  for _ in $(seq 20); do
    "${EWW[@]}" ping >/dev/null 2>&1 && break
    sleep 0.5
  done

  "${HOVER}" reset

  "${EWW[@]}" active-windows 2>/dev/null |
    awk -F': ' '$2 == "player-trigger" { print $1 }' |
    while read -r id; do
      "${EWW[@]}" close "${id}"
    done

  for monitor in $(polybar --list-monitors | cut -d: -f1); do
    "${EWW[@]}" open player-trigger --id "player-trigger-${monitor}" \
      --screen "${monitor}" --arg monitor="${monitor}"
  done
}

setup_desktops
# 9>&-: the bars outlive this script and must not inherit the lock.
"${HOME}/.config/polybar/launch.sh" >/dev/null 2>&1 9>&-
setup_player_triggers
