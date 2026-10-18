#!/bin/bash
# timeout bounds an IPC request that never gets an answer: without it the call
# waits forever and the script never reaches the rest.
#
# It does NOT cover the other failure, measured on eww 0.6.0: a client that
# cannot forward its command turns itself into a daemon and detaches (ppid 1).
# It exits successfully, so timeout has nothing left to kill, and a second
# daemon is left fighting over the socket. That one is still open.
timeout 5s eww -c ~/.config/eww open --toggle wifi
