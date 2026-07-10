#!/bin/bash
# Gets the current brightness percentage using light

light -G | cut -d. -f1
