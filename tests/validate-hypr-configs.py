#!/usr/bin/env python3
"""
Validates syntax and structural blocks for Hyprland ecosystem configurations,
specifically hypridle.conf and hyprlock.conf across core, templates, and host vaults.
"""

import glob
import os
import re
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def validate_hypr_conf(filepath: str) -> tuple[bool, str | None]:
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        # Strip comments (# ...)
        lines = content.splitlines()
        clean_lines = []
        for line in lines:
            stripped = re.sub(r"#.*$", "", line).strip()
            if stripped:
                clean_lines.append(stripped)
        clean_text = "\n".join(clean_lines)

        # Check balanced braces
        stack = []
        line_num = 1
        for ch in clean_text:
            if ch == "\n":
                line_num += 1
            elif ch == "{":
                stack.append(line_num)
            elif ch == "}":
                if not stack:
                    return False, f"Unexpected closing '}}' around line {line_num}"
                stack.pop()

        if stack:
            open_line = stack.pop()
            return False, f"Unclosed '{{' opened around line {open_line}"

        # Check for general block
        if not re.search(r"\bgeneral\s*\{", clean_text):
            return False, "Missing 'general' configuration block"

        # If hypridle, check for at least one listener with timeout
        if "hypridle" in filepath:
            if not re.search(r"\blistener\s*\{", clean_text):
                return False, "hypridle config missing 'listener' block"
            if not re.search(r"\btimeout\s*=", clean_text):
                return False, "hypridle config missing 'timeout' definition in listener"

        return True, None
    except Exception as e:
        return False, str(e)


def main() -> int:
    search_dirs = [
        os.path.join(REPO_ROOT, "hosts"),
        os.path.join(REPO_ROOT, "hyprland"),
    ]

    target_files = []
    for sdir in search_dirs:
        for pattern in ("*hypridle*.conf", "*hyprlock*.conf"):
            target_files.extend(glob.glob(os.path.join(sdir, "**", pattern), recursive=True))

    target_files = sorted(set([f for f in target_files if "/.git/" not in f and "/main/" not in f]))
    if not target_files:
        print("No hypridle or hyprlock configuration files found.")
        return 0

    failed = 0
    print(f"▶ Validating {len(target_files)} Hypridle & Hyprlock configurations...")

    for fpath in target_files:
        rel_path = os.path.relpath(fpath, REPO_ROOT)
        ok, err = validate_hypr_conf(fpath)
        if ok:
            print(f"  ✅ {rel_path}")
        else:
            print(f"  ❌ {rel_path}: {err}")
            failed += 1

    if failed > 0:
        print(f"\n❌ Hypr configuration validation failed on {failed} file(s).")
        return 1

    print(f"  🎉 All {len(target_files)} Hypridle & Hyprlock configs are structurally valid!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
