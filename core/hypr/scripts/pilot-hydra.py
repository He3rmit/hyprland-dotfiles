#!/usr/bin/env python3

import os
import time
import hashlib
import threading
import subprocess
import requests

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Pango

# 🚀 Pilot HUD — Hydra-Omega Hub (v1.5.0)
# Animated GIFs • Klipy Stickers • Local Vault • Dynamic Emojis

SECRETS_FILE = os.path.expanduser("~/.secrets.sh")
STICKER_DIR  = os.path.expanduser("~/Pictures/Stickers")
CACHE_DIR    = "/tmp/pilot-hydra"

os.makedirs(CACHE_DIR, exist_ok=True)

# ─── THEME ───────────────────────────────────────────────────────────────────

CSS_THEME = b"""
window {
    background-color: #11111b;
    border: 2px solid #94e2d5;
    border-radius: 12px;
}
entry {
    background-color: #1e1e2e;
    color: #cdd6f4;
    border: 1px solid #45475a;
    border-radius: 8px;
    padding: 10px;
    margin: 8px 10px;
    font-size: 14px;
}
button {
    background-color: #1e1e2e;
    border-radius: 6px;
    border: 1px solid #313244;
    padding: 2px;
}
button:hover {
    background-color: #313244;
    border-color: #94e2d5;
}
.emoji-btn {
    font-size: 28px;
    padding: 4px;
    background: none;
    border: none;
}
.emoji-btn:hover {
    background-color: #313244;
    border-radius: 6px;
}
notebook tab {
    background-color: #11111b;
    color: #a6adc8;
    padding: 8px 14px;
    font-size: 13px;
}
notebook tab:checked {
    background-color: #1e1e2e;
    color: #94e2d5;
    border-bottom: 2px solid #94e2d5;
}
flowbox {
    background-color: #181825;
    padding: 6px;
}
"""

# ─── HYDRA HUB ───────────────────────────────────────────────────────────────

class HydraHub(Gtk.Window):
    def __init__(self):
        super().__init__(title="Hydra Hub")
        self.set_default_size(600, 640)
        self.set_keep_above(True)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.api_key      = self._load_api_key()
        self.debounce_id  = None

        # Layout
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(root)

        # Search bar
        self.search = Gtk.Entry()
        self.search.set_placeholder_text("🔍  Search GIFs, Stickers, Emojis…")
        self.search.connect("changed", self._on_search_changed)
        root.pack_start(self.search, False, False, 0)

        # Notebook
        self.notebook = Gtk.Notebook()
        self.notebook.connect("switch-page", self._on_tab_switched)
        root.pack_start(self.notebook, True, True, 0)

        # Tabs
        self.gif_grid     = self._make_tab("GIFs",           animated=True)
        self.sticker_grid = self._make_tab("Klipy Stickers", animated=True)
        self.vault_grid   = self._make_tab("Local Vault",    animated=False)
        self.emoji_grid   = self._make_tab("Emojis",         animated=False)

        # CSS
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS_THEME)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.connect("destroy", Gtk.main_quit)
        self.show_all()

        # Background loaders
        self._cleanup_cache()
        self._load_vault()
        threading.Thread(target=self._load_emojis, daemon=True).start()

    # ─── SETUP ───────────────────────────────────────────────────────────────

    def _load_api_key(self):
        if os.path.exists(SECRETS_FILE):
            for line in open(SECRETS_FILE):
                if "KLIPY_API_KEY" in line and '"' in line:
                    return line.split('"')[1]
        print("[Hydra] WARNING: No API key found in ~/.secrets.sh")
        return None

    def _make_tab(self, title, animated=False):
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        fb = Gtk.FlowBox()
        fb.set_valign(Gtk.Align.START)
        fb.set_max_children_per_line(5)
        fb.set_column_spacing(4)
        fb.set_row_spacing(4)
        fb.set_homogeneous(False)
        fb.set_selection_mode(Gtk.SelectionMode.NONE)
        scrolled.add(fb)
        self.notebook.append_page(scrolled, Gtk.Label(label=title))
        return fb

    # ─── SEARCH DISPATCH ─────────────────────────────────────────────────────

    def _on_search_changed(self, entry):
        if self.debounce_id:
            GLib.source_remove(self.debounce_id)
        self.debounce_id = GLib.timeout_add(450, self._dispatch, entry.get_text().strip())

    def _on_tab_switched(self, notebook, page, page_num):
        """Re-fire the search when switching tabs so the grid is never stale."""
        query = self.search.get_text().strip()
        if query:
            if self.debounce_id:
                GLib.source_remove(self.debounce_id)
            self.debounce_id = GLib.timeout_add(100, self._dispatch_page, query, page_num)

    def _dispatch_page(self, query, page):
        self.debounce_id = None
        if page == 0:
            threading.Thread(target=self._fetch_gifs, args=(query,), daemon=True).start()
        elif page == 1:
            threading.Thread(target=self._fetch_stickers, args=(query,), daemon=True).start()
        return False

    def _dispatch(self, query):
        self.debounce_id = None
        page = self.notebook.get_current_page()
        if not query:
            return False
        if page == 0:
            threading.Thread(target=self._fetch_gifs, args=(query,), daemon=True).start()
        elif page == 1:
            threading.Thread(target=self._fetch_stickers, args=(query,), daemon=True).start()
        return False

    # ─── KLIPY GIFs  (v2: results[].media_formats) ───────────────────────────

    def _fetch_gifs(self, query):
        url = f"https://api.klipy.co/v2/search?q={query}&key={self.api_key}&limit=30"
        print(f"[Hydra/GIF] {url}")
        try:
            r = requests.get(url, timeout=6)
            print(f"[Hydra/GIF] HTTP {r.status_code}")
            if r.status_code != 200:
                print(f"[Hydra/GIF] body: {r.text[:200]}")
                return
            results = r.json().get("results", [])
            print(f"[Hydra/GIF] {len(results)} results")
            GLib.idle_add(self._clear, self.gif_grid)
            for item in results:
                try:
                    # nanogif for animated thumbnail (small, fast to load)
                    nano = item["media_formats"]["nanogif"]["url"]
                    full = item["media_formats"]["gif"]["url"]
                    data = requests.get(nano, timeout=6).content
                    GLib.idle_add(self._add_animated, self.gif_grid, data, full)
                except Exception as e:
                    print(f"[Hydra/GIF] item error: {e}")
        except Exception as e:
            print(f"[Hydra/GIF] fetch error: {e}")

    # ─── KLIPY STICKERS  (v2: data[].images) ─────────────────────────────────

    def _fetch_stickers(self, query):
        url = f"https://api.klipy.co/v2/stickers/search?q={query}&key={self.api_key}&limit=30"
        print(f"[Hydra/STK] {url}")
        try:
            r = requests.get(url, timeout=6)
            print(f"[Hydra/STK] HTTP {r.status_code}")
            if r.status_code != 200:
                print(f"[Hydra/STK] body: {r.text[:200]}")
                return
            items = r.json().get("data", [])
            print(f"[Hydra/STK] {len(items)} stickers")
            GLib.idle_add(self._clear, self.sticker_grid)
            for item in items:
                try:
                    imgs = item.get("images", {})
                    # fixed_width_small is ~100px wide animated GIF thumbnail
                    thumb_url = (imgs.get("fixed_width_small", {}).get("url")
                              or imgs.get("preview_gif", {}).get("url"))
                    full_url  = (imgs.get("original", {}).get("url") or thumb_url)
                    if not thumb_url:
                        continue
                    data = requests.get(thumb_url, timeout=6).content
                    GLib.idle_add(self._add_animated, self.sticker_grid, data, full_url)
                except Exception as e:
                    print(f"[Hydra/STK] item error: {e}")
        except Exception as e:
            print(f"[Hydra/STK] fetch error: {e}")

    # ─── LOCAL VAULT ─────────────────────────────────────────────────────────

    def _load_vault(self):
        os.makedirs(STICKER_DIR, exist_ok=True)
        files = [f for f in os.listdir(STICKER_DIR)
                 if f.lower().endswith((".png", ".gif", ".jpg", ".jpeg", ".webp"))]
        if not files:
            lbl = Gtk.Label(label="Vault is empty.\nDrop images into ~/Pictures/Stickers/")
            lbl.set_justify(Gtk.Justification.CENTER)
            self.vault_grid.add(lbl)
            self.vault_grid.show_all()
        else:
            for f in sorted(files):
                path = os.path.join(STICKER_DIR, f)
                GLib.idle_add(self._add_local, path)

    def _add_local(self, path):
        btn = Gtk.Button()
        btn.connect("clicked", self._on_click_local, path)
        try:
            pb = GdkPixbuf.Pixbuf.new_from_file_at_size(path, 130, 110)
            btn.add(Gtk.Image.new_from_pixbuf(pb))
            self.vault_grid.add(btn)
            self.vault_grid.show_all()
        except Exception as e:
            print(f"[Hydra/VLT] {e}")

    # ─── DYNAMIC EMOJIS ──────────────────────────────────────────────────────

    def _load_emojis(self):
        core = ["😀","😂","🤣","😊","😍","🤩","🥳","😭","😤","🤔",
                "😎","🥺","😜","🤯","🙄","😴","🤠","👍","❤️","🔥",
                "🚀","🛡️","🦾","✨","💎","🎯","🎉","👀","💀","🫡"]
        for e in core:
            GLib.idle_add(self._add_emoji, e)
        try:
            r = requests.get(
                "https://unicode.org/Public/emoji/15.0/emoji-test.txt",
                timeout=10)
            seen = set(core)
            for line in r.text.splitlines():
                if "; fully-qualified" in line:
                    try:
                        e = line.split("#")[1].split(" ")[1]
                        if e not in seen:
                            seen.add(e)
                            GLib.idle_add(self._add_emoji, e)
                    except: pass
        except Exception as e:
            print(f"[Hydra/EMJ] {e}")

    def _add_emoji(self, emoji):
        btn = Gtk.Button(label=emoji)
        btn.get_style_context().add_class("emoji-btn")
        btn.connect("clicked", lambda b, x=emoji: self._copy_text(x))
        self.emoji_grid.add(btn)
        self.emoji_grid.show_all()

    # ─── GTK GRID HELPERS ────────────────────────────────────────────────────

    def _add_animated(self, grid, img_data, full_url):
        """Add an animated or static image button to a FlowBox grid."""
        btn = Gtk.Button()
        btn.connect("clicked", self._on_click_media, full_url)
        try:
            loader = GdkPixbuf.PixbufLoader()
            loader.write(img_data)
            loader.close()

            anim = loader.get_animation()
            if anim and not anim.is_static_image():
                # 🎞️ Animated GIF — display looping animation
                widget = Gtk.Image.new_from_animation(anim)
            else:
                # Static fallback — preserve aspect ratio in a 150×120 box
                pb = anim.get_static_image() if anim else loader.get_pixbuf()
                w, h = pb.get_width(), pb.get_height()
                ratio = min(150 / w, 120 / h)
                pb = pb.scale_simple(max(1, int(w * ratio)),
                                     max(1, int(h * ratio)),
                                     GdkPixbuf.InterpType.BILINEAR)
                widget = Gtk.Image.new_from_pixbuf(pb)

            btn.add(widget)
            grid.add(btn)
            grid.show_all()
        except Exception as e:
            print(f"[Hydra] pixbuf error: {e}")

    def _clear(self, grid):
        for child in grid.get_children():
            grid.remove(child)

    # ─── CAPTURE ─────────────────────────────────────────────────────────────

    def _on_click_media(self, btn, url):
        threading.Thread(target=self._capture_url, args=(url,), daemon=True).start()

    def _capture_url(self, url):
        try:
            url_hash = hashlib.md5(url.encode()).hexdigest()[:12]
            cache_dir = os.path.expanduser("~/.cache/pilot-hydra")
            os.makedirs(cache_dir, exist_ok=True)
            cache_gif = os.path.join(cache_dir, f"ck_{url_hash}.gif")

            # 1. Download full animated GIF (only if not already cached)
            if not os.path.exists(cache_gif):
                data = requests.get(url, timeout=10).content
                with open(cache_gif, "wb") as f:
                    f.write(data)

            # 2. Copy as image/gif binary — Popen so thread never blocks
            with open(cache_gif, "rb") as f:
                proc = subprocess.Popen(
                    ["wl-copy", "--type", "image/gif"],
                    stdin=f,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
                proc.wait()  # wl-copy forks after reading — this returns quickly

            self._notify("GIF Copied", "Ctrl+V to paste")
        except Exception as e:
            print(f"[Hydra] capture error: {e}")

    def _cleanup_cache(self):
        """Purge cached files older than 24 hours to keep the pilot hub lean."""
        try:
            cache_dir = os.path.expanduser("~/.cache/pilot-hydra")
            if not os.path.exists(cache_dir):
                return
            now = time.time()
            for f in os.listdir(cache_dir):
                path = os.path.join(cache_dir, f)
                if os.stat(path).st_mtime < now - 86400:
                    os.remove(path)
        except Exception as e:
            print(f"[Hydra] cleanup error: {e}")


    def _on_click_local(self, btn, path):
        mime = "image/png" if path.lower().endswith(".png") else "image/gif"
        with open(path, "rb") as f:
            proc = subprocess.Popen(
                ["wl-copy", "--type", mime],
                stdin=f,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            proc.wait()
        self._notify("Captured", "Ctrl+V to paste")

    def _copy_text(self, text):
        subprocess.run(["wl-copy"], input=text.encode())
        self._notify("Captured", f"Emoji {text} copied.")

    def _notify(self, title, body):
        """Dispatch to GTK main thread — safe from any background thread."""
        GLib.idle_add(
            lambda: subprocess.run(
                ["notify-send", "-t", "2000", "-a", "Hydra Hub", title, body]
            ) and False
        )


# ─── LAUNCH ──────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    HydraHub()
    Gtk.main()
