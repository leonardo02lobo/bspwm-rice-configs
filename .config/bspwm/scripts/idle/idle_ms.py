#!/usr/bin/env python3
"""Prints milliseconds since the last input event.

This exists because X's own idle machinery does not work on this machine: the
screensaver timer reaches zero and never activates, and the DPMS timers never
fire either (measured — 103s of idle against a 15s timeout, monitor still on).
The idle counter itself is perfectly reliable, so everything is driven from it.

Uses the XScreenSaver extension through ctypes rather than xprintidle, which
would do the same job but is not installed and would need root to add.
"""

import ctypes
import ctypes.util
import sys


class ScreenSaverInfo(ctypes.Structure):
    _fields_ = [
        ("window", ctypes.c_ulong),
        ("state", ctypes.c_int),
        ("kind", ctypes.c_int),
        ("til_or_since", ctypes.c_ulong),
        ("idle", ctypes.c_ulong),
        ("event_mask", ctypes.c_ulong),
    ]


def idle_ms() -> int:
    xlib = ctypes.CDLL(ctypes.util.find_library("X11") or "libX11.so.6")
    xss = ctypes.CDLL(ctypes.util.find_library("Xss") or "libXss.so.1")

    xlib.XOpenDisplay.restype = ctypes.c_void_p
    xlib.XDefaultRootWindow.restype = ctypes.c_ulong
    xlib.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
    xss.XScreenSaverAllocInfo.restype = ctypes.POINTER(ScreenSaverInfo)
    xss.XScreenSaverQueryInfo.argtypes = [
        ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(ScreenSaverInfo)
    ]

    display = xlib.XOpenDisplay(None)
    if not display:
        raise RuntimeError("no display")
    info = xss.XScreenSaverAllocInfo()
    xss.XScreenSaverQueryInfo(display, xlib.XDefaultRootWindow(display), info)
    return int(info.contents.idle)


if __name__ == "__main__":
    try:
        print(idle_ms())
    except Exception:
        print(0)  # a broken query must not look like idleness
        sys.exit(1)
