#!/bin/bash
# Decreases brightness by 5% and shows the EWW widget

light -U 5

# Show widget
~/.config/bspwm/scripts/brightness/show_brightness_widget.sh &
