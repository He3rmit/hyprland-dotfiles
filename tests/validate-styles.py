#!/usr/bin/env python3
"""
Validates all CSS and Rofi RASI style files across the repository.
Checks for syntax errors, unclosed blocks, and mismatched brackets.
"""

import glob
import os
import re
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def validate_style_syntax(filepath: str) -> tuple[bool, str | None]:
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            raw = f.read()

        # 1. Strip comments (/* ... */ and // ...)
        clean = re.sub(r'/\*.*?\*/', '', raw, flags=re.DOTALL)
        clean = re.sub(r'//[^\n]*', '', clean)

        # 2. Check balanced braces, brackets, and parentheses
        stack = []
        pairs = { '}': '{', ')': '(', ']': '[' }
        openers = set(pairs.values())

        line_num = 1
        for ch in clean:
            if ch == '\n':
                line_num += 1
            elif ch in openers:
                stack.append((ch, line_num))
            elif ch in pairs:
                if not stack:
                    return False, f"Unexpected closing '{ch}' around line {line_num}"
                top, top_line = stack.pop()
                if top != pairs[ch]:
                    return False, f"Mismatched '{top}' (from line {top_line}) closed by '{ch}' at line {line_num}"

        if stack:
            top, top_line = stack.pop()
            return False, f"Unclosed '{top}' opened at line {top_line}"

        return True, None
    except Exception as e:
        return False, str(e)


def main() -> int:
    search_dir = os.path.join(REPO_ROOT, "core")

    target_files = []
    for ext in ("*.css", "*.rasi"):
        target_files.extend(glob.glob(os.path.join(search_dir, "**", ext), recursive=True))

    target_files = sorted(set(target_files))
    if not target_files:
        print("No CSS or RASI style files found to validate.")
        return 0

    failed = 0
    print(f"▶ Validating {len(target_files)} CSS and RASI style files...")

    for fpath in target_files:
        rel_path = os.path.relpath(fpath, REPO_ROOT)
        ok, err = validate_style_syntax(fpath)
        if ok:
            print(f"  ✅ {rel_path}")
        else:
            print(f"  ❌ {rel_path}: {err}")
            failed += 1

    if failed > 0:
        print(f"\n❌ Style validation failed on {failed} file(s).")
        return 1

    print(f"  🎉 All {len(target_files)} style files passed structural validation!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
