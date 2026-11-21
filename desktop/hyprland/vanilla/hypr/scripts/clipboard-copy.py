#!/usr/bin/env python3
import sys

text = sys.stdin.read()
if not text:
    sys.exit(0)

try:
    import gi
    gi.require_version('Gtk', '3.0')
    from gi.repository import Gtk, Gdk
    Gtk.init([])
    cb = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
    cb.set_text(text, -1)
    cb.store()
except Exception:
    pass
