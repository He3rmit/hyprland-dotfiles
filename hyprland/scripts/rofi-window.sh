#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: rofi-window.sh
# Purpose: Wayland Native Active Window Switcher for Hyprland
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/rofi-window.py" "$@"
