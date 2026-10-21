#!/usr/bin/env python3
"""
Titanfall Instant Window Quick-Flip (Cross-Workspace A/B Toggle)
Features:
  - Instantly toggles focus between your current window and previous window across any workspace.
  - Zero UI, zero latency (~10ms execution).
  - Uses Hyprland's native focusHistoryID MRU stack.
"""

import json
import subprocess
import sys


def main():
    try:
        raw = subprocess.check_output(["hyprctl", "clients", "-j"], stderr=subprocess.DEVNULL)
        clients = json.loads(raw)
    except Exception:
        sys.exit(0)

    # Filter valid, mapped windows
    valid_clients = [
        c for c in clients
        if c.get("mapped", True) and c.get("title") and not c.get("hidden", False)
    ]

    if len(valid_clients) < 2:
        sys.exit(0)

    # Sort by Most-Recently-Used (focusHistoryID: 0 = current, 1 = previous)
    valid_clients.sort(key=lambda c: c.get("focusHistoryID", 999))

    prev_window = valid_clients[1]
    addr = prev_window.get("address", "")

    if addr:
        res = subprocess.run(
            ["hyprctl", "dispatch", f'hl.dsp.focus({{ window = "address:{addr}" }})'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if res.returncode != 0:
            subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{addr}"])


if __name__ == "__main__":
    main()
