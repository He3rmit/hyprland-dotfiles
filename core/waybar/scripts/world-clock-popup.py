#!/usr/bin/env python3
# ==============================================================================
# TITAN PILOT HUD: WORLD CLOCK & TIMEZONE POPUP (GTK3 Native)
# ==============================================================================

import os
import sys
import datetime
import subprocess

try:
    import zoneinfo
except ImportError:
    from backports import zoneinfo

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, GLib, Pango

CITIES = [
    ("Asia/Manila", "Manila", "Philippines (PHT)"),
    ("Asia/Tokyo", "Tokyo", "Japan (JST)"),
    ("UTC", "UTC", "Universal Coordinated Time"),
    ("Europe/London", "London", "United Kingdom (BST/GMT)"),
    ("Europe/Paris", "Paris", "France (CEST/CET)"),
    ("Europe/Berlin", "Berlin", "Germany (CEST/CET)"),
    ("America/New_York", "New York", "United States (EDT/EST)"),
    ("America/Chicago", "Chicago", "United States (CDT/CST)"),
    ("America/Denver", "Denver", "United States (MDT/MST)"),
    ("America/Los_Angeles", "Los Angeles", "United States (PDT/PST)"),
    ("Asia/Singapore", "Singapore", "Singapore (SGT)"),
    ("Asia/Hong_Kong", "Hong Kong", "China (HKT)"),
    ("Asia/Shanghai", "Shanghai / Beijing", "China (CST)"),
    ("Asia/Kolkata", "New Delhi / Mumbai", "India (IST)"),
    ("Asia/Dubai", "Dubai", "UAE (GST)"),
    ("Australia/Sydney", "Sydney", "Australia (AEST/AEDT)"),
    ("Pacific/Auckland", "Auckland", "New Zealand (NZST/NZDT)"),
]

CSS = b"""
window {
    background-color: #0d1117;
    border: 2px solid #00aeef;
    border-radius: 12px;
    box-shadow: 0 0 15px rgba(0, 174, 239, 0.4);
}

entry {
    background-color: #161b22;
    color: #58a6ff;
    border: 1px solid #30363d;
    border-radius: 8px;
    padding: 8px 12px;
    font-size: 14px;
    margin: 10px 10px 5px 10px;
}

entry:focus {
    border-color: #00aeef;
    box-shadow: 0 0 5px rgba(0, 174, 239, 0.5);
}

scrolledwindow {
    margin: 5px 10px 10px 10px;
}

row {
    padding: 8px 12px;
    border-radius: 6px;
    margin-bottom: 2px;
}

row:hover {
    background-color: rgba(0, 174, 239, 0.15);
}

row:selected {
    background-color: #00aeef;
    color: #0d1117;
}

.city-title {
    font-weight: bold;
    font-size: 14px;
    color: #ffffff;
}

.city-sub {
    font-size: 11px;
    color: #8b949e;
}

.city-time {
    font-family: monospace;
    font-weight: bold;
    font-size: 15px;
    color: #00aeef;
}
"""

class WorldClockPopup(Gtk.Window):
    def __init__(self):
        super().__init__(title="World Clock")
        self.set_type_hint(Gdk.WindowTypeHint.DIALOG)
        self.set_decorations(Gdk.WMDecoration.ALL)
        self.set_border_width(0)
        self.set_default_size(420, 380)
        self.set_position(Gtk.WindowPosition.MOUSE)
        self.set_keep_above(True)

        # Apply CSS
        style_provider = Gtk.CssProvider()
        style_provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.add(vbox)

        # Search Entry
        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text(" Search city or timezone...")
        self.entry.set_icon_from_icon_name(Gtk.EntryIconPosition.PRIMARY, "system-search-symbolic")
        self.entry.connect("changed", self.on_search_changed)
        self.entry.connect("activate", self.on_entry_activate)
        vbox.pack_start(self.entry, False, False, 0)

        # Scrolled Window & ListBox
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        vbox.pack_start(scrolled, True, True, 0)

        self.listbox = Gtk.ListBox()
        self.listbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.listbox.connect("row-activated", self.on_row_activated)
        scrolled.add(self.listbox)

        # Populate rows
        self.rows_data = []
        self.populate_cities()

        # Connect focus loss to close
        self.connect("focus-out-event", lambda w, e: self.destroy())

        self.show_all()

    def populate_cities(self):
        now_utc = datetime.datetime.now(datetime.timezone.utc)

        for tz_id, city, country in CITIES:
            try:
                tz = zoneinfo.ZoneInfo(tz_id)
                local_dt = now_utc.astimezone(tz)
                time_str = local_dt.strftime("%H:%M")
                tz_code = local_dt.strftime("%Z (UTC%z)")
                date_str = local_dt.strftime("%a, %b %d")

                row = Gtk.ListBoxRow()
                hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
                hbox.set_padding(4, 4)

                vbox_left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
                lbl_city = Gtk.Label(xalign=0)
                lbl_city.set_markup(f"<b>{city}</b> <span color='#8b949e'>· {country}</span>")

                lbl_sub = Gtk.Label(xalign=0)
                lbl_sub.set_markup(f"<span size='small' color='#8b949e'>{date_str} · {tz_code}</span>")

                vbox_left.pack_start(lbl_city, False, False, 0)
                vbox_left.pack_start(lbl_sub, False, False, 0)

                lbl_time = Gtk.Label(xalign=1)
                lbl_time.set_markup(f"<span font_family='monospace' size='large' weight='bold' color='#00aeef'>{time_str}</span>")

                hbox.pack_start(vbox_left, True, True, 0)
                hbox.pack_end(lbl_time, False, False, 0)

                row.add(hbox)
                self.listbox.add(row)

                search_key = f"{city} {country} {tz_id} {tz_code}".lower()
                self.rows_data.append((row, search_key, city, time_str, tz_code, date_str))

            except Exception as e:
                continue

    def on_search_changed(self, entry):
        query = entry.get_text().lower().strip()
        first_visible = None

        for row, key, city, time_str, tz_code, date_str in self.rows_data:
            if not query or query in key:
                row.show_all()
                if first_visible is None:
                    first_visible = row
            else:
                row.hide()

        if first_visible:
            self.listbox.select_row(first_visible)

    def on_entry_activate(self, entry):
        selected = self.listbox.get_selected_row()
        if selected:
            self.on_row_activated(self.listbox, selected)

    def on_row_activated(self, listbox, row):
        idx = row.get_index()
        for r, key, city, time_str, tz_code, date_str in self.rows_data:
            if r == row:
                subprocess.Popen([
                    "notify-send", "-u", "normal", "-a", "World Clock",
                    "-i", "clock",
                    f"󰥔 {city}",
                    f"Time: {time_str} {tz_code}\nDate: {date_str}"
                ])
                break
        self.destroy()

if __name__ == "__main__":
    app = WorldClockPopup()
    Gtk.main()
