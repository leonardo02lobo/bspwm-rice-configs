# BSPWM Rice Configs

Personal BSPWM setup with custom EWW widgets and hardware-friendly input configuration.

## What's included

| Component | Path | Description |
|-----------|------|-------------|
| Brightness widget | `.config/eww/brightness/` | EWW OSD with dynamic icon and progress bar |
| Volume widget | `.config/eww/volume/` | EWW OSD for volume/mute feedback |
| WiFi widget | `.config/eww/wifi/` | EWW popup for scanning/connecting networks |
| Scripts | `.config/bspwm/scripts/` | Helper scripts for brightness, volume, WiFi and touchpad |
| Hotkeys | `.config/sxhkd/sxhkdrc` | Keyboard bindings (F5/F6 brightness, `super + ctrl + w` WiFi, media keys) |
| Touchpad | `.config/bspwm/touchpad/` + `etc/X11/xorg.conf.d/` | libinput config for tap-to-click, natural scrolling and disable-while-typing |
| BSPWM | `.config/bspwm/bspwmrc` | Session startup with daemons and touchpad setup |

## Key features

- **Brightness OSD**: controlled via `light` with 5% steps; auto-closes after 3 seconds.
- **Volume OSD**: 5% steps with mute state; auto-closes after 3 seconds.
- **WiFi widget**: toggle radio, scan networks, connect/disconnect with `nmcli` + `rofi` password prompt.
- **Touchpad**: works like a laptop touchpad (tap-to-click, two-finger right click, three-finger middle click, natural scrolling, disable while typing).

## Requirements

- BSPWM
- EWW (ElKowar's Wacky Widgets)
- sxhkd
- `light` (brightness)
- `brightnessctl` (fallback)
- `pactl` / PulseAudio (volume)
- `nmcli` / NetworkManager (WiFi)
- `xinput` + `libinput` driver (touchpad runtime setup)

## Installation

1. Clone/copy the repo to your machine:
   ```bash
   git clone https://github.com/leonardo02lobo/bspwm-rice-configs.git
   cd bspwm-rice-configs
   ```

2. Sync the dotfiles to your `~/.config` (back up first):
   ```bash
   cp -r .config/* ~/.config/
   ```

3. Install the touchpad X11 config (requires root):
   ```bash
   sudo mkdir -p /etc/X11/xorg.conf.d
   sudo cp etc/X11/xorg.conf.d/90-touchpad-libinput.conf /etc/X11/xorg.conf.d/
   ```

4. Install dependencies:
   ```bash
   sudo apt install -y xinput libinput-tools light brightnessctl
   ```

5. Restart your BSPWM / Xorg session.

## Hotkeys

| Key | Action |
|-----|--------|
| `F5` / `XF86MonBrightnessDown` | Decrease brightness |
| `F6` / `XF86MonBrightnessUp` | Increase brightness |
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Volume up/down |
| `XF86AudioMute` | Mute toggle |
| `super + ctrl + w` | Toggle WiFi widget |

## License

Personal configuration — use and adapt as you wish.
