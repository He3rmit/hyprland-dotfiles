#!/usr/bin/env bash
# ==============================================================================
# SCRIPT SMOKE TESTS
# Runs non-interactive functional tests against core dotfiles helper scripts.
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "▶ Running Functional Smoke Tests on Scripts..."

# 1. Test gamemode.sh contract
echo "  [1/4] Testing gamemode.sh (--status & --check)..."
status_out=$("$REPO_ROOT/hyprland/scripts/gamemode.sh" --status)
if [[ "$status_out" != *"tooltip"* ]]; then
    echo "❌ gamemode.sh --status returned unexpected output: $status_out"
    exit 1
fi

check_out=$("$REPO_ROOT/hyprland/scripts/gamemode.sh" --check)
if [[ "$check_out" != "true" && "$check_out" != "false" ]]; then
    echo "❌ gamemode.sh --check returned non-boolean: $check_out"
    exit 1
fi
echo "  ✅ gamemode.sh CLI contract verified."

# 2. Test pilot-control master utility
echo "  [2/4] Testing pilot-control CLI..."
pilot_out=$("$REPO_ROOT/home/.local/bin/pilot-control" --help || true)
if [[ "$pilot_out" != *"MASTER CONTROL PROTOCOL"* ]]; then
    echo "❌ pilot-control failed to render master protocol header"
    exit 1
fi
echo "  ✅ pilot-control CLI verified."

# 3. Test lib-bind-engine AST parser
echo "  [3/4] Testing lib-bind-engine AST parser on keybinds.lua..."
parsed_count=$(bash -c "source '$REPO_ROOT/hyprland/scripts/lib-bind-engine.sh' && parse_bind_file '$REPO_ROOT/hyprland/modules/keybinds.lua' && print_bind_list | wc -l")
if [ "$parsed_count" -lt 15 ]; then
    echo "❌ lib-bind-engine only parsed $parsed_count bindings from keybinds.lua (expected >= 15)"
    exit 1
fi
echo "  ✅ lib-bind-engine successfully parsed $parsed_count bindings."

# 4. Test mic.sh safe error contract
echo "  [4/4] Testing mic.sh usage safety..."
set +e
mic_err=$("$REPO_ROOT/hyprland/scripts/mic.sh" 2>&1)
mic_code=$?
set -e
if [ $mic_code -eq 0 ] || [[ "$mic_err" != *"Usage"* && "$mic_err" != *"wpctl not found"* ]]; then
    echo "❌ mic.sh did not fail safely: $mic_err"
    exit 1
fi
echo "  ✅ mic.sh safe fallback verified."

echo "  🎉 All script smoke tests passed successfully!"
