#!/usr/bin/env python3
"""
Validates all JSON and JSONC configuration files across the repository.
Handles JSONC syntax (single-line // comments, block /* */ comments, and trailing commas)
specifically used by Waybar and Fastfetch.
"""

import glob
import json
import os
import re
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def strip_jsonc_comments_and_trailing_commas(content: str) -> str:
    # 1. Strip double-quote string literals temporarily to preserve comments inside strings
    # or regex match strings vs comments
    def replacer(match):
        s = match.group(0)
        if s.startswith("/"):
            return ""  # It's a comment
        return s

    pattern = re.compile(
        r'("(?:\\.|[^"\\])*")|//[^\n]*|/\*.*?\*/',
        re.DOTALL,
    )
    clean = pattern.sub(replacer, content)

    # 2. Strip trailing commas before closing braces/brackets
    clean = re.sub(r",(\s*[}\]])", r"\1", clean)
    return clean


def validate_file(filepath: str) -> tuple[bool, str | None]:
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            raw = f.read()
        cleaned = strip_jsonc_comments_and_trailing_commas(raw)
        json.loads(cleaned)
        return True, None
    except Exception as e:
        return False, str(e)


def main() -> int:
    search_dirs = [
        os.path.join(REPO_ROOT, "core"),
        os.path.join(REPO_ROOT, "hosts"),
    ]

    target_files = []
    for sdir in search_dirs:
        for ext in ("*.json", "*.jsonc"):
            target_files.extend(glob.glob(os.path.join(sdir, "**", ext), recursive=True))

    target_files = sorted(set(target_files))
    if not target_files:
        print("No JSON or JSONC files found to validate.")
        return 0

    failed = 0
    print(f"▶ Validating {len(target_files)} JSON/JSONC configuration files...")

    for fpath in target_files:
        rel_path = os.path.relpath(fpath, REPO_ROOT)
        ok, err = validate_file(fpath)
        if ok:
            print(f"  ✅ {rel_path}")
        else:
            print(f"  ❌ {rel_path}: {err}")
            failed += 1

    if failed > 0:
        print(f"\n❌ JSON/JSONC validation failed on {failed} file(s).")
        return 1

    print(f"  🎉 All {len(target_files)} JSON/JSONC files are valid!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
