#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: rofi-command-palette.sh
# Purpose: Wrapper for Titanfall Unified Command Palette (Spotlight / Raycast style)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/rofi-command-palette.py" "$@"
