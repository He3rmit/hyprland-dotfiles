#!/usr/bin/env python3
"""
Titanfall Active Window Switcher (Wayland Native for Hyprland)
Features:
  - Discovers all open windows across all workspaces & monitors via hyprctl.
  - Sorted by Most-Recently-Used (MRU) focus history.
  - Displays Workspace badges, window titles, app classes, and high-res icons.
  - Enter: Instantly focus and switch to the selected window's workspace.
  - Shift + Delete: Remotely close the selected window without switching to it.
"""

import json
import os
import subprocess
import sys

ROFI_THEME = os.path.expanduser("~/.config/rofi/themes/window.rasi")
CACHE_FILE = "/tmp/rofi_command_palette_apps.json"


def get_icon_map():
    """Builds a class-to-icon lookup from cached desktop applications."""
    icon_map = {
        "zen": "zen",
        "zen-browser": "zen",
        "antigravity-ide": "antigravity-ide",
        "kitty": "kitty",
        "thunar": "org.xfce.thunar",
        "firefox": "firefox",
        "chromium": "chromium",
        "google-chrome": "google-chrome",
        "discord": "discord",
        "spotify": "spotify",
        "steam": "steam",
        "code": "vscode",
    }
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            for app in data.get("apps", []):
                desktop = os.path.basename(app.get("desktop", "")).replace(".desktop", "").lower()
                icon = app.get("icon", "")
                if desktop and icon:
                    icon_map[desktop] = icon
                name = app.get("name", "").lower()
                if name and icon:
                    icon_map[name] = icon
        except Exception:
            pass
    return icon_map


def focus_window(address: str):
    """Switches workspace and focuses window using Hyprland Lua dispatcher with fallback."""
    res = subprocess.run(
        ["hyprctl", "dispatch", f'hl.dsp.focus({{ window = "address:{address}" }})'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if res.returncode != 0:
        subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"])


def close_window(address: str):
    """Closes window using Hyprland Lua dispatcher with fallback."""
    res = subprocess.run(
        ["hyprctl", "dispatch", f'hl.dsp.window.close({{ window = "address:{address}" }})'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if res.returncode != 0:
        subprocess.run(["hyprctl", "dispatch", "closewindow", f"address:{address}"])


def main():
    try:
        raw = subprocess.check_output(["hyprctl", "clients", "-j"], stderr=subprocess.DEVNULL)
        clients = json.loads(raw)
    except Exception as e:
        subprocess.run(["notify-send", "-a", "Window Switcher", "Hyprctl Error", str(e)])
        sys.exit(1)

    # Filter valid, mapped windows with a title
    valid_clients = [
        c for c in clients
        if c.get("mapped", True) and c.get("title") and not c.get("hidden", False)
    ]

    if not valid_clients:
        subprocess.run([
            "notify-send",
            "-a", "Window Switcher",
            "-i", "preferences-system-windows",
            "Window Switcher",
            "No active windows found.",
        ])
        sys.exit(0)

    # Sort by Most-Recently-Used (focusHistoryID: 0 = current, 1 = previous)
    valid_clients.sort(key=lambda c: c.get("focusHistoryID", 999))

    icon_map = get_icon_map()

    display_map = {}
    rofi_lines = []
    for c in valid_clients:
        ws_name = c.get("workspace", {}).get("name", "?")
        if ws_name.startswith("special:"):
            ws_label = f"[{ws_name.replace('special:', '')}]"
        else:
            ws_label = f"[{ws_name}]"

        title = c.get("title", "").strip()
        if len(title) > 68:
            title = title[:65] + "..."

        cls = c.get("class", "").strip()
        display = f"{ws_label:<5}  {title}  ({cls})"
        display_map[display] = c

        # Icon resolution
        cls_lower = cls.lower()
        icon = icon_map.get(cls_lower, cls_lower)

        addr = c.get("address", "")
        meta = f"{cls} {ws_name} {title}"
        line = f"{display}\0icon\x1f{icon}\x1finfo\x1f{addr}\x1fmeta\x1f{meta}"
        rofi_lines.append(line)

    rofi_input = "\n".join(rofi_lines)

    rofi_cmd = [
        "rofi",
        "-dmenu",
        "-i",
        "-p", "󰍹 Windows",
        "-show-icons",
        "-kb-custom-1", "Alt+Delete",
        "-mesg", "Enter: Focus Window  |  Alt+Delete: Close Window  |  Esc: Cancel",
    ]

    if os.path.exists(ROFI_THEME):
        rofi_cmd.extend(["-theme", ROFI_THEME])

    # If 2 or more windows exist, pre-select index 1 (previous window) for quick toggle
    if len(valid_clients) > 1:
        rofi_cmd.extend(["-selected-row", "1"])

    try:
        proc = subprocess.run(
            rofi_cmd,
            input=rofi_input,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
    except Exception as e:
        subprocess.run(["notify-send", "-a", "Window Switcher", "Rofi Error", str(e)])
        sys.exit(1)

    def resolve_target(raw_out: str):
        s = raw_out.strip()
        if not s or s == "-1":
            return valid_clients[1] if len(valid_clients) > 1 else valid_clients[0]
        if s in display_map:
            return display_map[s]
        q = s.lower()
        for client in valid_clients:
            c_class = client.get("class", "").lower()
            c_title = client.get("title", "").lower()
            if q == c_class or q in c_title or q in c_class:
                return client
        return valid_clients[1] if len(valid_clients) > 1 else valid_clients[0]

    # Alt + Delete to kill window (Rofi returns code 10 on custom-1)
    if proc.returncode == 10:
        target = resolve_target(proc.stdout)
        if target:
            close_window(target["address"])
            subprocess.run([
                "notify-send",
                "-a", "Window Switcher",
                "-i", "window-close",
                "Window Terminated",
                f"Closed {target.get('title', 'window')}",
            ])
        sys.exit(0)

    if proc.returncode != 0:
        sys.exit(0)

    target = resolve_target(proc.stdout)
    if target:
        focus_window(target["address"])


if __name__ == "__main__":
    main()
