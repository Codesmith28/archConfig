#!/usr/bin/env python3
"""
Lightweight, multi-format clipboard history daemon for Wayland/Hyprland.
Monitors GTK clipboard changes and safely stores:
- Full multi-line text entries (preserving all formatting and newlines)
- High-fidelity image thumbnails (128x128) and full PNG copies
- Single-line indexed summaries formatted for Wofi image previews
- Backward-compatible entries in ~/.cache/clipboard_history.txt
"""
import os
import sys
import hashlib
import time

CACHE_DIR = os.path.expanduser("~/.cache/clipboard")
ENTRIES_DIR = os.path.join(CACHE_DIR, "entries")
THUMBS_DIR = os.path.join(CACHE_DIR, "thumbnails")
INDEX_FILE = os.path.join(CACHE_DIR, "index.txt")
LEGACY_FILE = os.path.expanduser("~/.cache/clipboard_history.txt")
MAX_ENTRIES = 100

os.makedirs(ENTRIES_DIR, exist_ok=True)
os.makedirs(THUMBS_DIR, exist_ok=True)

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

try:
    import gi
    gi.require_version('Gtk', '3.0')
    from gi.repository import Gtk, Gdk, GLib
    HAS_GTK = True
except ImportError:
    HAS_GTK = False


def update_index(new_entry_line, new_hash, legacy_text):
    """Inserts the new entry at the head of the index and legacy file, pruning duplicates."""
    lines = []
    if os.path.exists(INDEX_FILE):
        try:
            with open(INDEX_FILE, "r", encoding="utf-8", errors="replace") as f:
                lines = [line.strip() for line in f if line.strip()]
        except Exception:
            lines = []

    # Filter out existing matching hash
    lines = [l for l in lines if f"({new_hash})" not in l]
    lines.insert(0, new_entry_line)
    lines = lines[:MAX_ENTRIES]

    try:
        with open(INDEX_FILE, "w", encoding="utf-8") as f:
            for l in lines:
                f.write(l + "\n")
    except Exception:
        pass

    # Update legacy history file
    legacy_lines = []
    if os.path.exists(LEGACY_FILE):
        try:
            with open(LEGACY_FILE, "r", encoding="utf-8", errors="replace") as f:
                legacy_lines = [l.strip() for l in f if l.strip()]
        except Exception:
            legacy_lines = []

    legacy_clean = " ".join(legacy_text.split())
    if legacy_clean:
        legacy_lines = [l for l in legacy_lines if l != legacy_clean]
        legacy_lines.insert(0, legacy_clean)
        legacy_lines = legacy_lines[:MAX_ENTRIES]
        try:
            with open(LEGACY_FILE, "w", encoding="utf-8") as f:
                for l in legacy_lines:
                    f.write(l + "\n")
        except Exception:
            pass


def handle_text(text):
    if not text or not text.strip():
        return
    text_bytes = text.encode("utf-8")
    entry_hash = hashlib.sha256(text_bytes).hexdigest()[:16]

    # Save full multi-line text
    full_path = os.path.join(ENTRIES_DIR, f"{entry_hash}.txt")
    try:
        with open(full_path, "w", encoding="utf-8") as f:
            f.write(text)
    except Exception:
        return

    # Create summary for UI
    lines = text.strip().splitlines()
    line_count = len(lines)
    byte_count = len(text_bytes)
    first_line = lines[0].strip()[:70].replace(":", " ")

    if line_count > 1:
        summary = f"{first_line} [{line_count} lines, {byte_count}B] ({entry_hash})"
    else:
        summary = f"{first_line} ({entry_hash})"

    index_line = f"text:{summary}"
    update_index(index_line, entry_hash, first_line)


def handle_image(pixbuf):
    if not pixbuf:
        return
    try:
        # Save full image to bytes
        success, buffer = pixbuf.save_to_bufferv("png", [], [])
        if not success or not buffer:
            return
        img_bytes = bytes(buffer)
        entry_hash = hashlib.sha256(img_bytes).hexdigest()[:16]

        full_path = os.path.join(ENTRIES_DIR, f"{entry_hash}.png")
        with open(full_path, "wb") as f:
            f.write(img_bytes)

        # Generate 128x128 thumbnail
        thumb_path = os.path.join(THUMBS_DIR, f"{entry_hash}.png")
        w, h = pixbuf.get_width(), pixbuf.get_height()

        if HAS_PIL:
            with Image.open(full_path) as im:
                im.thumbnail((128, 128))
                im.save(thumb_path, "PNG")
        else:
            scale_w = 128
            scale_h = int(128 * (h / max(1, w)))
            if scale_h > 128:
                scale_h = 128
                scale_w = int(128 * (w / max(1, h)))
            scaled = pixbuf.scale_simple(max(1, scale_w), max(1, scale_h), GdkPixbuf.InterpType.BILINEAR)
            scaled.savev(thumb_path, "png", [], [])

        label = f"[Image] {w}x{h} PNG ({entry_hash})"
        index_line = f"img:{thumb_path}:text:{label}"
        update_index(index_line, entry_hash, f"[Image] {w}x{h}")
    except Exception as e:
        sys.stderr.write(f"Image save error: {e}\n")


def on_clipboard_owner_change(clipboard, event):
    # Check targets
    targets = clipboard.wait_for_targets()
    if targets is None:
        return

    # Check for image target first
    if clipboard.wait_is_image_available():
        pixbuf = clipboard.wait_for_image()
        if pixbuf:
            handle_image(pixbuf)
            return

    # Fall back to text
    if clipboard.wait_is_text_available():
        text = clipboard.wait_for_text()
        if text:
            handle_text(text)


def main():
    if not HAS_GTK:
        sys.exit(0)

    ok = Gtk.init_check()
    if not ok or not ok[0]:
        try:
            Gdk.init([])
            Gtk.init([])
        except Exception:
            pass

    display = Gdk.Display.get_default()
    if not display:
        sys.exit(0)

    clipboard = Gtk.Clipboard.get_default(display)
    if not clipboard:
        sys.exit(0)

    clipboard.connect("owner-change", on_clipboard_owner_change)
    loop = GLib.MainLoop()
    loop.run()


if __name__ == "__main__":
    main()
