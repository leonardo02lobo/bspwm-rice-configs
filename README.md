# BSPWM Rice Configs

Personal BSPWM setup with custom EWW widgets and hardware-friendly input configuration.

## What's included

| Component | Path | Description |
|-----------|------|-------------|
| Brightness widget | `.config/eww/brightness/` | EWW OSD with dynamic icon and progress bar |
| Volume widget | `.config/eww/volume/` | EWW OSD for volume/mute feedback |
| WiFi widget | `.config/eww/wifi/` | EWW popup for scanning/connecting networks |
| Spotify widget | `.config/eww/player/` | Floating EWW panel anchored below the Polybar bar |
| Scripts | `.config/bspwm/scripts/` | Helper scripts for brightness, volume, WiFi and touchpad |
| Hotkeys | `.config/sxhkd/sxhkdrc` | Keyboard bindings (F5/F6 brightness, `super + ctrl + w` WiFi, media keys) |
| Touchpad | `.config/bspwm/touchpad/` + `etc/X11/xorg.conf.d/` | libinput config for tap-to-click, natural scrolling and disable-while-typing |
| BSPWM | `.config/bspwm/bspwmrc` | Session startup with daemons and touchpad setup |

## Key features

- **Brightness OSD**: controlled via `light` with 5% steps; auto-closes after 3 seconds.
- **Volume OSD**: 5% steps with mute state; auto-closes after 3 seconds.
- **WiFi widget**: toggle radio, scan networks, connect/disconnect with `nmcli` + `rofi` password prompt.
- **Spotify widget**: track metadata, playback controls, shuffle and repeat, driven over MPRIS with `playerctl`. Controls are shared with the media keys through `.config/sxhkd/scripts/spotify_control`, so both paths behave the same. The panel anchors to the top right, clearing the Polybar top bar by `4px`. Those offsets were measured with `xwininfo` against the running bar, not read from a config file — `config.ini` looks authoritative but `launch.sh` never loads it, so its numbers are wrong. **If you change the bar's height or margin, re-measure and update the offsets in `.config/eww/player/player.yuck`.** The panel opens on X's primary output, which is what the running bars follow. Album art is cached under `~/.cache/eww/player-art`, keyed by track id and capped at 100 covers (~6MB); it downloads in the background so the one-second poll never waits on the network, which means a cover appears about a second after the track changes. Deleting that directory is safe — it refills itself.
- **Spotify hover trigger**: a Spotify icon sits in the bar's free gap and reveals the player panel on hover, sliding it down and hiding it when the pointer leaves. Its position comes from the measured gap between bar modules (`x 1078..1242`), so **re-measure with `xwininfo` if you change the bar's modules**. Hiding is deferred by a grace delay and then decided by where the pointer actually is: GTK fires leave events when the pointer crosses onto child widgets, and the icon and panel are separate windows, so cancelling by bookkeeping loses a race that checking the pointer does not. The panel window is closed rather than left collapsed, since eww does not shrink a toplevel back down and an invisible one would swallow clicks. Coexists with `super + ctrl + s`.
- **Touchpad**: works like a laptop touchpad (tap-to-click, two-finger right click, three-finger middle click, natural scrolling, disable while typing).

## Requirements

- BSPWM
- EWW (ElKowar's Wacky Widgets)
- sxhkd
- `light` (brightness)
- `brightnessctl` (fallback)
- `pactl` / PulseAudio (volume)
- `nmcli` / NetworkManager (WiFi)
- `playerctl` (Spotify control over MPRIS)
- `jq` (builds the player state snapshot)
- `xdotool` (the hover trigger checks the pointer's position before hiding)
- `xinput` + `libinput` driver (touchpad runtime setup)

## Installation

1. Clone/copy the repo to your machine:
   ```bash
   git clone https://github.com/leonardo02lobo/bspwm-rice-configs.git
   cd bspwm-rice-configs
   ```

2. Sync the dotfiles to your `~/.config` (back up first):
   ```bash
   ./sync.sh
   ```
   `~/.config` holds real copies, not symlinks, so editing this repo changes
   nothing until you run this. Use `./sync.sh --check` to list what differs
   between the two sides without writing anything — worth running before you
   edit, since the live config can drift ahead of git.

3. Install the touchpad X11 config (requires root):
   ```bash
   sudo mkdir -p /etc/X11/xorg.conf.d
   sudo cp etc/X11/xorg.conf.d/90-touchpad-libinput.conf /etc/X11/xorg.conf.d/
   ```

4. Install dependencies:
   ```bash
   sudo apt install -y xinput libinput-tools light brightnessctl playerctl jq
   ```

5. Restart your BSPWM / Xorg session.

> **Note**: `~/.config/polybar/` is not tracked in this repository, so changes
> there are manual and unversioned. Be aware that `config.ini` is dead weight:
> `launch.sh` loads `current.ini` and `workspace.ini` instead, so the bar you
> see on screen is `principal_bar`, not the `[bar/main]` defined in
> `config.ini`. Measure with `xwininfo` before trusting any of those values.

## Hotkeys

| Key | Action |
|-----|--------|
| `F5` / `XF86MonBrightnessDown` | Decrease brightness |
| `F6` / `XF86MonBrightnessUp` | Increase brightness |
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Volume up/down |
| `XF86AudioMute` | Mute toggle |
| `super + ctrl + w` | Toggle WiFi widget |
| `super + ctrl + s` | Toggle Spotify widget |
| `XF86AudioPlay` / `Stop` / `Prev` / `Next` | Spotify playback control |
| `super + F10` / `F11` | Seek 8s backward / forward |
| `super + Pause` / `Delete` | Repeat playlist / repeat track |

## License

Personal configuration — use and adapt as you wish.
