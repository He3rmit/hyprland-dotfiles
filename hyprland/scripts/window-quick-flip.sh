#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: window-quick-flip.sh
# Purpose: Instant cross-workspace A/B window toggle for Hyprland
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/window-quick-flip.py" "$@"
