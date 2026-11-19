#!/usr/bin/env bash
# ==============================================================================
# LOCAL CI VALIDATION RUNNER
# Run this script before pushing to verify syntax, permissions, configs,
# keybind integrity, and multi-template stowing.
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "========================================================"
echo "  PILOT HUD DOTFILES — LOCAL CI SANITY CHECK"
echo "========================================================"
echo ""

# --- 1. SHELL SYNTAX ---
echo "▶ Checking Shell Script Syntax (bash -n)..."
sh_count=0
while IFS= read -r -d '' f; do
    bash -n "$f" || { echo "❌ Syntax error in $f"; exit 1; }
    sh_count=$((sh_count + 1))
done < <(find . -name "*.sh" -not -path "./.git/*" -not -path "./main/*" -print0)
echo "  ✅ Passed: $sh_count shell scripts verified."

# --- 2. LUA SYNTAX ---
if command -v luac >/dev/null 2>&1; then
    echo "▶ Checking Lua Syntax (luac -p)..."
    lua_count=0
    while IFS= read -r -d '' f; do
        luac -p "$f" || { echo "❌ Lua syntax error in $f"; exit 1; }
        lua_count=$((lua_count + 1))
    done < <(find . -name "*.lua" -not -path "./.git/*" -not -path "./main/*" -print0)
    echo "  ✅ Passed: $lua_count Lua modules verified."
else
    echo "  ⚠️ luac not found, skipping Lua parse check."
fi

# --- 3. PYTHON SYNTAX & LINT ---
echo "▶ Checking Python Syntax (py_compile)..."
py_count=0
while IFS= read -r -d '' f; do
    python3 -m py_compile "$f" || { echo "❌ Python syntax error in $f"; exit 1; }
    py_count=$((py_count + 1))
done < <(find . -name "*.py" -not -path "./.git/*" -not -path "./main/*" -print0)
echo "  ✅ Passed: $py_count Python scripts compiled."

RUFF_BIN="$(command -v ruff 2>/dev/null || true)"
if [[ -z "$RUFF_BIN" && -x "/tmp/ruff-x86_64-unknown-linux-gnu/ruff" ]]; then
    RUFF_BIN="/tmp/ruff-x86_64-unknown-linux-gnu/ruff"
fi
if [[ -n "$RUFF_BIN" ]]; then
    echo "▶ Checking Python Linting (ruff check)..."
    "$RUFF_BIN" check hyprland/scripts/ tests/ || { echo "❌ Ruff linting failed"; exit 1; }
    echo "  ✅ Passed: Ruff linting clean."
else
    echo "  ⚠️ ruff not found, skipping Python lint check."
fi

# --- 4. JSON & JSONC CONFIGURATION VALIDATION ---
"$ROOT_DIR/tests/validate-jsonc.py"

# --- 5. CSS & RASI STYLE VALIDATION ---
"$ROOT_DIR/tests/validate-styles.py"

# --- 6. KEYBINDING TARGET INTEGRITY ---
"$ROOT_DIR/tests/validate-keybind-targets.py"

# --- 7. SCRIPT FUNCTIONAL SMOKE TESTS ---
"$ROOT_DIR/tests/test-scripts-smoke.sh"

# --- 8. PERMISSIONS CHECK ---
echo "▶ Checking Executable Bits on Scripts..."
perm_fail=0
for f in $(git ls-files "*.sh" "*.py"); do
    if [[ ! -x "$f" ]]; then
        echo "  ❌ Not executable: $f"
        perm_fail=1
    fi
done
if [[ $perm_fail -ne 0 ]]; then
    echo "❌ One or more scripts lack executable permissions in git."
    exit 1
fi
echo "  ✅ Passed: All tracked scripts have executable (+x) permissions."

# --- 9. BROKEN SYMLINKS ---
echo "▶ Checking for Broken Symlinks..."
broken=$(find . -xtype l -not -path "./.git/*" -not -path "./main/*")
if [[ -n "$broken" ]]; then
    echo "  ❌ Broken symlinks found in repo:"
    echo "$broken"
    exit 1
fi
echo "  ✅ Passed: Zero broken symlinks in repository."

# --- 10. HOST PRIVACY ENFORCEMENT ---
echo "▶ Checking Host Profile Privacy Rules..."
leaked_hosts=$(git ls-files "hosts/" | grep -v "^hosts/_template/" || true)
if [[ -n "$leaked_hosts" ]]; then
    echo "  ❌ Leaked host profile detected in git index:"
    echo "$leaked_hosts"
    exit 1
fi
echo "  ✅ Passed: Only template host profile is tracked in git."

# --- 11. SECRET LEAK CHECK ---
echo "▶ Checking for Tracked Secrets..."
leaked_secrets=$(git ls-files "*secret*" | grep -v "\.example$" || true)
if [[ -n "$leaked_secrets" ]]; then
    echo "  ❌ Security violation: Secret file tracked in git index:"
    echo "$leaked_secrets"
    exit 1
fi
echo "  ✅ Passed: No secret files tracked."

# --- 12. MULTI-TEMPLATE GNU STOW SIMULATION ---
"$ROOT_DIR/tests/test-stow-templates.sh"

echo ""
echo "========================================================"
echo "  🎉 ALL 12 LOCAL CI CHECKS PASSED SUCCESSFULLY!"
echo "========================================================"
