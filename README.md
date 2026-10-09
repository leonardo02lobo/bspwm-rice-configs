# BSPWM Rice Configs

Personal BSPWM setup with custom EWW widgets and hardware-friendly input configuration.

## What's included

| Component | Path | Description |
|-----------|------|-------------|
| Brightness widget | `.config/eww/brightness/` | EWW OSD with dynamic icon and progress bar |
| Volume widget | `.config/eww/volume/` | EWW OSD for volume/mute feedback |
| WiFi widget | `.config/eww/wifi/` | EWW popup for scanning/connecting networks |
| Polybar | `.config/polybar/` | Six floating bars (`launch.sh`, `current.ini`, `workspace.ini`), one set per monitor |
| Spotify widget | `.config/eww/player/` | EWW trigger in each bar's gap with a floating hover panel anchored below the bar |
| Multi-monitor | `.config/bspwm/scripts/monitors/` | Per-monitor desktops, bars and Spotify trigger, plus a hotplug listener |
| Scripts | `.config/bspwm/scripts/` | Helper scripts for brightness, volume, WiFi and touchpad |
| Hotkeys | `.config/sxhkd/sxhkdrc` | Keyboard bindings (F5/F6 brightness, `super + ctrl + w` WiFi, media keys) |
| Touchpad | `.config/bspwm/touchpad/` + `etc/X11/xorg.conf.d/` | libinput config for tap-to-click, natural scrolling and disable-while-typing |
| BSPWM | `.config/bspwm/bspwmrc` | Session startup with daemons, touchpad and monitor setup |

## Key features

- **Brightness OSD**: controlled via `light` with 5% steps; auto-closes after 3 seconds.
- **Volume OSD**: 5% steps with mute state; auto-closes after 3 seconds.
- **WiFi widget**: toggle radio, scan networks, connect/disconnect with `nmcli` + `rofi` password prompt.
- **Multi-monitor**: every active monitor gets its own set of bars and Spotify trigger. The laptop panel (`eDP`) holds desktops `I..VI` and the external monitor `VII..X`, so `super + 1..0` reaches the external directly. The external is always placed right of the laptop. Plugging, unplugging or toggling the external with `xrandr` reconfigures everything; on unplug its desktops and windows move to the laptop and return when it comes back. Only one external monitor is supported.
- **Focus follows pointer**: the window under the mouse gets focus (clicking still focuses too).
- **Spotify widget**: track metadata, playback controls, shuffle and repeat, driven over MPRIS with `playerctl`. Controls are shared with the media keys through `.config/sxhkd/scripts/spotify_control`, so both paths behave the same. The panel anchors to the top right, clearing the Polybar top bar by `4px`. Those offsets were measured with `xwininfo` against the running bar, not read from a config file — `config.ini` looks authoritative but `launch.sh` never loads it, so its numbers are wrong. **If you change the bar's height or margin, re-measure and update the offsets in `.config/eww/player/player.yuck`.** Every monitor's bar has its own trigger, and the panel opens on the monitor whose trigger is hovered.
- **Idle, screensaver and lock**: three staggered stages — the idle screen at 5 min, the lock at 10, DPMS off at 15. A watcher polls how long the session has been idle and drives all three, because X's own idle machinery is inert here: the screensaver timer reaches zero and never activates, and the DPMS timers never fire either — measured, 103s of idle against a 15s timeout with the monitor still on. The panel is therefore powered off explicitly rather than scheduled. `xss-lock` is still used, but only with `--ignore-xss`, for the half that does work: locking before suspend, whether that comes from `super + F12` or from closing the lid. The idle screen is decoration only: it is an eww window per connected output showing the clock and what is playing, it holds no keyboard grab, and the lock always follows it. The lock deliberately does **not** blur a screenshot of the desktop — a blur still shows the shape of what was open, and this laptop gets locked in public places — so it uses the wallpaper instead. **Video does not inhibit the lock**, in a browser or in `mpv`: browsers ask through `org.freedesktop.ScreenSaver`, a D-Bus name nobody owns here, and although `mpv` suspends X's screensaver, this server does not reflect that in the extension's state — it was tested during a real suspend and still reported `Off` while the idle counter kept climbing. Use `super + ctrl + i` while watching. `xfce4-screensaver` must stay disabled: it is installed and D-Bus activatable, and two lockers fighting over the keyboard grab is worse than none.
- **Touchpad**: works like a laptop touchpad (tap-to-click, two-finger right click, three-finger middle click, natural scrolling, disable while typing).

## Requirements

- BSPWM
- EWW (ElKowar's Wacky Widgets) 0.6+
- Polybar
- `xdotool`, `xwininfo` (Spotify widget hover)
- `xrandr` (monitor setup)
- sxhkd
- `light` (brightness)
- `brightnessctl` (fallback)
- `pactl` / PulseAudio (volume)
- `nmcli` / NetworkManager (WiFi)
- `playerctl` (Spotify control over MPRIS)
- `jq` (player state snapshot and monitor setup)
- `xss-lock` (idle detection, and locking before suspend)
- `i3lock-color` (installed as `i3lock`; the lock screen's clock and ring)
- `imagemagick` (renders the lock background once per screen geometry)
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
   sudo apt install -y xinput libinput-tools light brightnessctl playerctl jq xss-lock
   ```

5. Restart your BSPWM / Xorg session.

> **Note**: two steps live outside this repository and have to be done by hand:
> disabling `xfce4-screensaver` (its autostart entry in `/etc/xdg/autostart/`
> and its D-Bus activation), and adding the inhibition indicator to Polybar.
>
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
| `super + 1..0` | Focus desktop `I..X` (`VII..X` live on the external monitor) |
| `super + ctrl + s` | Toggle Spotify widget |
| `super + shift + Escape` | Lock the session now |
| `super + ctrl + i` | Suspend/resume the automatic lock |
| `XF86AudioPlay` / `Stop` / `Prev` / `Next` | Spotify playback control |
| `super + F10` / `F11` | Seek 8s backward / forward |
| `super + Pause` / `Delete` | Repeat playlist / repeat track |

## License

Personal configuration — use and adapt as you wish.
