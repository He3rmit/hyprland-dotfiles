#!/usr/bin/env python3
"""
Validates that all scripts referenced by Hyprland keybindings exist in the
repository and have executable (+x) permissions.
Prevents broken shortcuts caused by script renames or deletions.
"""

import os
import re
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

KEYBIND_SOURCES = [
    os.path.join(REPO_ROOT, "hyprland/modules/keybinds.lua"),
    os.path.join(REPO_ROOT, "hosts/_template/laptop/hypr-host.lua"),
    os.path.join(REPO_ROOT, "hosts/_template/desktop/hypr-host.lua"),
]


def resolve_script_path(module_dir: str, script_name: str) -> str:
    """Maps runtime ~/.config paths back to repository paths."""
    if module_dir == "hypr":
        return os.path.join(REPO_ROOT, "hyprland", "scripts", script_name)
    return os.path.join(REPO_ROOT, "core", module_dir, "scripts", script_name)


def main() -> int:
    print("▶ Validating Keybinding Target Script Integrity...")
    total_checked = 0
    errors = []

    pattern = re.compile(r'~/\.config/(hypr|waybar|swaync)/scripts/([^"\'\s)]+)')

    for src_file in KEYBIND_SOURCES:
        if not os.path.exists(src_file):
            continue

        rel_src = os.path.relpath(src_file, REPO_ROOT)
        with open(src_file, "r", encoding="utf-8") as f:
            content = f.read()

        matches = pattern.findall(content)
        for mod, script in matches:
            total_checked += 1
            target_repo_path = resolve_script_path(mod, script)
            rel_target = os.path.relpath(target_repo_path, REPO_ROOT)

            if not os.path.exists(target_repo_path):
                errors.append(f"{rel_src}: references '{mod}/scripts/{script}', but '{rel_target}' does not exist!")
            elif not os.access(target_repo_path, os.X_OK):
                errors.append(f"{rel_target}: is referenced in keybinds but is missing executable (+x) permissions!")
            else:
                print(f"  ✅ [{rel_src}] -> {rel_target}")

    if errors:
        print(f"\n❌ Found {len(errors)} broken keybinding reference(s):")
        for err in errors:
            print(f"  ❌ {err}")
        return 1

    print(f"  🎉 All {total_checked} referenced script targets exist and are executable!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
