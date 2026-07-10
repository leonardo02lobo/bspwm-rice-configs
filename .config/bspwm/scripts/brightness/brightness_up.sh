#!/bin/bash
# Increases brightness by 5% and shows the EWW widget

light -A 5

# Show widget
~/.config/bspwm/scripts/brightness/show_brightness_widget.sh &
