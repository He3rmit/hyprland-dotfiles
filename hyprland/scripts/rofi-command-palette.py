#!/usr/bin/env python3
"""
Titanfall Command Palette (Raycast / Spotlight-style unified launcher for Rofi)
Features:
  - High-performance desktop application launcher with icon support & caching.
  - Safe in-line arithmetic & scientific calculator (copies result to clipboard).
  - Web quick-search bangs:
      ? / !g  : Google Search
      !w      : ArchWiki Search
      !yt     : YouTube Search
      !gh     : GitHub Search
      !ddg    : DuckDuckGo Search
      !r      : Reddit Search
  - Direct URL opener (https://..., or domain.com).
  - Terminal command executor (> <command> in floating Kitty).
  - Automatic web search fallback for unmatched queries.
"""

import ast
import json
import math
import operator as op
import os
import re
import subprocess
import sys
import urllib.parse

CACHE_FILE = "/tmp/rofi_command_palette_apps.json"
ROFI_THEME = os.path.expanduser("~/.config/rofi/themes/launcher.rasi")

DESKTOP_DIRS = [
    os.path.expanduser("~/.local/share/applications"),
    "/usr/share/applications",
    "/var/lib/flatpak/exports/share/applications",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
]

# ──────────────────────────────────────────────────────────────────────────────
#  1. SAFE ARITHMETIC / MATH EVALUATOR
# ──────────────────────────────────────────────────────────────────────────────
OPS = {
    ast.Add: op.add,
    ast.Sub: op.sub,
    ast.Mult: op.mul,
    ast.Div: op.truediv,
    ast.FloorDiv: op.floordiv,
    ast.Mod: op.mod,
    ast.Pow: op.pow,
    ast.USub: op.neg,
    ast.UAdd: op.pos,
}

ALLOWED_FUNCS = {
    "sqrt": math.sqrt,
    "sin": math.sin,
    "cos": math.cos,
    "tan": math.tan,
    "asin": math.asin,
    "acos": math.acos,
    "atan": math.atan,
    "log": math.log,
    "log10": math.log10,
    "log2": math.log2,
    "exp": math.exp,
    "ceil": math.ceil,
    "floor": math.floor,
    "abs": abs,
    "round": round,
    "pow": pow,
    "pi": math.pi,
    "e": math.e,
}


def safe_eval_math(expr_str: str):
    """Safely evaluates an arithmetic expression using Python AST."""
    cleaned = expr_str.strip().replace("^", "**")
    # Replace multiplication 'x' between digits (e.g. 50x12 -> 50*12)
    cleaned = re.sub(r"(?<=\d)\s*[xX]\s*(?=\d)", " * ", cleaned)

    def _eval(node):
        if isinstance(node, ast.Expression):
            return _eval(node.body)
        if isinstance(node, ast.Constant):
            if isinstance(node.value, (int, float, complex)):
                return node.value
            raise ValueError("Only numbers allowed")
        if isinstance(node, ast.Name):
            if node.id in ALLOWED_FUNCS:
                return ALLOWED_FUNCS[node.id]
            raise ValueError(f"Unknown symbol: {node.id}")
        if isinstance(node, ast.BinOp):
            if type(node.op) in OPS:
                left = _eval(node.left)
                right = _eval(node.right)
                return OPS[type(node.op)](left, right)
            raise ValueError(f"Unsupported operator: {node.op}")
        if isinstance(node, ast.UnaryOp):
            if type(node.op) in OPS:
                operand = _eval(node.operand)
                return OPS[type(node.op)](operand)
            raise ValueError(f"Unsupported unary operator: {node.op}")
        if isinstance(node, ast.Call):
            func = _eval(node.func)
            args = [_eval(arg) for arg in node.args]
            return func(*args)
        raise TypeError(f"Unsupported AST node: {type(node).__name__}")

    tree = ast.parse(cleaned, mode="eval")
    return _eval(tree)


def looks_like_math(text: str) -> bool:
    """Returns True if the text resembles a math expression."""
    s = text.strip()
    if not s:
        return False
    # Check for basic math characters: digits, math operators, parens, decimal
    if re.search(r"[\+\-\*\/\^\%]", s) and re.search(r"\d", s):
        # Exclude flags or command patterns like '-Syu' or '--help'
        if re.search(r"[a-zA-Z]{3,}", s):
            # Check if it starts with an allowed math function
            for func in ALLOWED_FUNCS:
                if s.startswith(func + "(") or s.startswith(func + " "):
                    return True
            return False
        return True
    # Functions like sqrt(144) or abs(-5)
    for func in ALLOWED_FUNCS:
        if re.match(rf"^{func}\s*\(.*\)$", s):
            return True
    return False


# ──────────────────────────────────────────────────────────────────────────────
#  2. APPLICATION INDEXING & CACHING
# ──────────────────────────────────────────────────────────────────────────────
def get_directories_mtime() -> float:
    """Returns the latest modification timestamp of application directories."""
    max_mtime = 0.0
    for d in DESKTOP_DIRS:
        if os.path.isdir(d):
            try:
                m = os.path.getmtime(d)
                if m > max_mtime:
                    max_mtime = m
            except OSError:
                pass
    return max_mtime


def load_cached_apps():
    """Loads apps from cache if up to date, otherwise rescans."""
    latest_mtime = get_directories_mtime()
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                cache = json.load(f)
            if cache.get("mtime", 0.0) >= latest_mtime:
                return cache.get("apps", [])
        except Exception:
            pass

    # Rescan .desktop files
    apps = scan_desktop_apps()
    try:
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump({"mtime": latest_mtime, "apps": apps}, f)
    except Exception:
        pass
    return apps


def scan_desktop_apps():
    """Scans and parses all system and user .desktop files."""
    seen_ids = set()
    apps = []

    for d in DESKTOP_DIRS:
        if not os.path.isdir(d):
            continue
        try:
            filenames = os.listdir(d)
        except OSError:
            continue

        for fname in filenames:
            if not fname.endswith(".desktop"):
                continue
            if fname in seen_ids:
                continue
            seen_ids.add(fname)

            fpath = os.path.join(d, fname)
            try:
                with open(fpath, "r", encoding="utf-8", errors="ignore") as fp:
                    name = None
                    generic_name = ""
                    exec_cmd = None
                    icon = ""
                    keywords = ""
                    categories = ""
                    nodisplay = False
                    terminal = False
                    in_entry = False

                    for line in fp:
                        line = line.strip()
                        if line == "[Desktop Entry]":
                            in_entry = True
                            continue
                        elif line.startswith("[") and in_entry:
                            break
                        if not in_entry or not line or line.startswith("#"):
                            continue

                        if line.startswith("Name=") and name is None:
                            name = line[5:]
                        elif line.startswith("GenericName=") and not generic_name:
                            generic_name = line[12:]
                        elif line.startswith("Exec=") and exec_cmd is None:
                            exec_cmd = line[5:]
                        elif line.startswith("Icon=") and not icon:
                            icon = line[5:]
                        elif line.startswith("Keywords=") and not keywords:
                            keywords = line[9:]
                        elif line.startswith("Categories=") and not categories:
                            categories = line[11:]
                        elif line.startswith("NoDisplay=true") or line.startswith("Hidden=true"):
                            nodisplay = True
                        elif line.startswith("Terminal=true"):
                            terminal = True

                    if name and exec_cmd and not nodisplay:
                        meta = f"{generic_name} {keywords} {categories}".replace(";", " ").strip()
                        apps.append({
                            "name": name,
                            "exec": exec_cmd,
                            "icon": icon or "application-x-executable",
                            "desktop": fpath,
                            "terminal": terminal,
                            "meta": meta,
                        })
            except Exception:
                continue

    apps.sort(key=lambda x: x["name"].lower())
    return apps


# ──────────────────────────────────────────────────────────────────────────────
#  3. APPLICATION LAUNCHING
# ──────────────────────────────────────────────────────────────────────────────
def launch_app(app):
    """Launches an application either in terminal or via GUI launcher."""
    raw_exec = app.get("exec", "")
    # Strip %f, %u, %F, %U, etc.
    clean_exec = re.sub(r"%[a-zA-Z]", "", raw_exec).strip()

    if app.get("terminal", False):
        subprocess.Popen(
            ["kitty", "-e", "bash", "-c", clean_exec],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return

    desktop_file = app.get("desktop", "")
    # Prefer gio launch for standard desktop integration
    if desktop_file and os.path.exists(desktop_file):
        try:
            res = subprocess.run(
                ["gio", "launch", desktop_file],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if res.returncode == 0:
                return
        except Exception:
            pass

    # Fallback to direct process spawn
    try:
        subprocess.Popen(
            clean_exec,
            shell=True,
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception as e:
        subprocess.run(["notify-send", "-a", "Command Palette", "-u", "critical", "Launch Error", str(e)])


# ──────────────────────────────────────────────────────────────────────────────
#  4. MAIN CONTROLLER
# ──────────────────────────────────────────────────────────────────────────────
def main():
    initial_filter = sys.argv[1] if len(sys.argv) > 1 else ""

    apps = load_cached_apps()
    name_to_app = {app["name"]: app for app in apps}

    # Helper quick actions
    helpers = [
        {"name": "  Run Terminal Command", "icon": "utilities-terminal", "meta": "run terminal bash exec cmd >", "action": "helper:> "},
        {"name": "󰍉  Search Web (Google)", "icon": "google-chrome", "meta": "google search web internet ? !g", "action": "helper:? "},
        {"name": "󰣇  Search ArchWiki", "icon": "archlinux", "meta": "arch archlinux wiki documentation manual !w", "action": "helper:!w "},
        {"name": "󰗃  Search YouTube", "icon": "youtube", "meta": "youtube video stream media !yt", "action": "helper:!yt "},
        {"name": "󰊤  Search GitHub", "icon": "github", "meta": "github git repo code source !gh", "action": "helper:!gh "},
        {"name": "󰍹  Switch Open Window", "icon": "preferences-system-windows", "meta": "window task switch alt tab ws workspace @", "action": "helper:window"},
        {"name": "󰪚  Math Calculator", "icon": "accessories-calculator", "meta": "calculator math eval calculate plus minus times divide", "action": "helper:calc"},
    ]
    helper_dict = {h["name"]: h["action"] for h in helpers}

    # Build Rofi input stream
    rofi_lines = []
    # 1. Apps
    for app in apps:
        line = f"{app['name']}\0icon\x1f{app['icon']}\x1fmeta\x1f{app['meta']}"
        rofi_lines.append(line)
    # 2. Helpers
    for h in helpers:
        line = f"{h['name']}\0icon\x1f{h['icon']}\x1fmeta\x1f{h['meta']}"
        rofi_lines.append(line)

    rofi_input = "\n".join(rofi_lines)

    rofi_cmd = ["rofi", "-dmenu", "-i", "-p", " ", "-show-icons"]
    if os.path.exists(ROFI_THEME):
        rofi_cmd.extend(["-theme", ROFI_THEME])
    if initial_filter:
        rofi_cmd.extend(["-filter", initial_filter])

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
        subprocess.run(["notify-send", "-a", "Command Palette", "Rofi Error", str(e)])
        sys.exit(1)

    if proc.returncode != 0 or not proc.stdout:
        sys.exit(0)

    choice = proc.stdout.strip()
    if not choice:
        sys.exit(0)

    # ── Check Helper Buttons ───────────────────────────────────────────────────
    if choice in helper_dict:
        action = helper_dict[choice]
        if action.startswith("helper:"):
            prefix = action[7:]
            if prefix == "calc":
                os.execv(sys.executable, [sys.executable, __file__, "24 * 60"])
            elif prefix == "window":
                window_script = os.path.join(os.path.dirname(__file__), "rofi-window.py")
                os.execv(sys.executable, [sys.executable, window_script])
            else:
                os.execv(sys.executable, [sys.executable, __file__, prefix])
        return

    # ── Window Switcher Prefix (@ <query> or w <query>) ───────────────────────
    if choice.startswith("@ ") or choice.startswith("w "):
        window_script = os.path.join(os.path.dirname(__file__), "rofi-window.py")
        os.execv(sys.executable, [sys.executable, window_script])
        return

    # ── 1. Terminal Command Runner (> <cmd> or : <cmd>) ───────────────────────
    if choice.startswith(">") or choice.startswith(": "):
        cmd = choice.lstrip(">:").strip()
        if cmd:
            subprocess.Popen(
                ["kitty", "--class", "floating", "-e", "bash", "-c", f"{cmd}; echo ''; echo 'Press Enter to exit...'; read -r"],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        return

    # ── 2. Web Bangs ──────────────────────────────────────────────────────────
    bang_match = re.match(r"^(![a-zA-Z]+|\?)\s*(.*)$", choice)
    if bang_match:
        bang = bang_match.group(1).lower()
        query = bang_match.group(2).strip()

        bang_urls = {
            "?": "https://www.google.com/search?q=",
            "!g": "https://www.google.com/search?q=",
            "!w": "https://wiki.archlinux.org/index.php?search=",
            "!yt": "https://www.youtube.com/results?search_query=",
            "!gh": "https://github.com/search?q=",
            "!ddg": "https://duckduckgo.com/?q=",
            "!r": "https://www.reddit.com/search/?q=",
        }

        if bang in bang_urls:
            target_url = bang_urls[bang] + urllib.parse.quote_plus(query)
            subprocess.Popen(["xdg-open", target_url], start_new_session=True)
            return

    # ── 3. Direct URLs ────────────────────────────────────────────────────────
    if re.match(r"^https?://", choice, re.IGNORECASE):
        subprocess.Popen(["xdg-open", choice], start_new_session=True)
        return

    domain_match = re.match(r"^[a-zA-Z0-9.-]+\.(com|org|net|io|dev|app|me|edu|gov|tech|de|uk|jp|cn|xyz|info)(/.*)?$", choice, re.IGNORECASE)
    if domain_match:
        subprocess.Popen(["xdg-open", f"https://{choice}"], start_new_session=True)
        return

    # ── 4. In-line Math Calculations ──────────────────────────────────────────
    if looks_like_math(choice):
        try:
            res = safe_eval_math(choice)
            if isinstance(res, (int, float, complex)):
                if isinstance(res, float) and res.is_integer():
                    res_str = str(int(res))
                elif isinstance(res, float):
                    res_str = f"{res:.6f}".rstrip("0").rstrip(".")
                else:
                    res_str = str(res)

                # Copy to clipboard via wl-copy
                try:
                    subprocess.run(["wl-copy", res_str], check=False)
                except Exception:
                    pass

                # Notify user
                subprocess.run([
                    "notify-send",
                    "-a", "Command Palette",
                    "-i", "accessories-calculator",
                    "Calculator Result",
                    f"{choice} = {res_str}\n(Copied to clipboard)",
                ], check=False)
                return
        except Exception:
            pass  # Fall through to app match or web search

    # ── 5. Application Launch ─────────────────────────────────────────────────
    if choice in name_to_app:
        launch_app(name_to_app[choice])
        return

    # Case-insensitive app lookup fallback
    for name, app in name_to_app.items():
        if name.lower() == choice.lower():
            launch_app(app)
            return

    # ── 6. Web Search Fallback ────────────────────────────────────────────────
    # Query did not match any installed app, bang, or calculation -> search Google
    fallback_url = "https://www.google.com/search?q=" + urllib.parse.quote_plus(choice)
    subprocess.Popen(["xdg-open", fallback_url], start_new_session=True)
    subprocess.run([
        "notify-send",
        "-a", "Command Palette",
        "-i", "preferences-system-search",
        "Web Search",
        f"Searching Google for '{choice}'...",
    ], check=False)


if __name__ == "__main__":
    main()
