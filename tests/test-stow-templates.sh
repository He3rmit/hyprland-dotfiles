#!/usr/bin/env bash
# ==============================================================================
# MOCK DEPLOYMENT & TEMPLATE STOWING TEST
# Tests deployment of home, core, and host templates in an isolated mock HOME.
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v stow >/dev/null 2>&1; then
    echo "⚠️ GNU Stow not installed. Skipping deployment test."
    exit 0
fi

echo "▶ Testing Mock Deployment of Host Templates..."

for template in "laptop" "desktop"; do
    echo "  >> Testing template: $template..."
    MOCK_HOME=$(mktemp -d /tmp/mock-home-XXXXXX)
    mkdir -p "$MOCK_HOME/.config/hypr" "$MOCK_HOME/.config/waybar" "$MOCK_HOME/.config/swaync"

    # 1. Stow home
    stow -v --no-folding -t "$MOCK_HOME" home >/dev/null 2>&1

    # 2. Stow core
    stow -v --no-folding -t "$MOCK_HOME/.config" core >/dev/null 2>&1

    # 3. Deploy template
    TEMPLATE_DIR="$REPO_ROOT/hosts/_template/$template"
    if [ ! -d "$TEMPLATE_DIR" ]; then
        echo "❌ Template directory missing: $TEMPLATE_DIR"
        rm -rf "$MOCK_HOME"
        exit 1
    fi

    # Link template host configs
    ln -sf "$TEMPLATE_DIR/hypr-host.lua" "$MOCK_HOME/.config/hypr/hypr-host.lua"
    ln -sf "$TEMPLATE_DIR/profile.conf" "$MOCK_HOME/.config/hypr/profile.conf"
    if [ -f "$TEMPLATE_DIR/hypridle.conf" ]; then
        ln -sf "$TEMPLATE_DIR/hypridle.conf" "$MOCK_HOME/.config/hypr/hypridle.conf"
    else
        ln -sf "$REPO_ROOT/hyprland/hypridle.conf" "$MOCK_HOME/.config/hypr/hypridle.conf"
    fi
    if [ -f "$TEMPLATE_DIR/hyprlock.conf" ]; then
        ln -sf "$TEMPLATE_DIR/hyprlock.conf" "$MOCK_HOME/.config/hypr/hyprlock.conf"
    else
        ln -sf "$REPO_ROOT/hyprland/hyprlock.conf" "$MOCK_HOME/.config/hypr/hyprlock.conf"
    fi

    # 4. Assert integrity
    [ -L "$MOCK_HOME/.zshrc" ] || { echo "❌ Failed: .zshrc symlink missing"; rm -rf "$MOCK_HOME"; exit 1; }
    [ -f "$MOCK_HOME/.config/swaync/config.json" ] || { echo "❌ Failed: swaync config.json missing"; rm -rf "$MOCK_HOME"; exit 1; }
    [ -f "$MOCK_HOME/.config/waybar/common.jsonc" ] || { echo "❌ Failed: waybar common.jsonc missing"; rm -rf "$MOCK_HOME"; exit 1; }
    [ -f "$MOCK_HOME/.config/hypr/hypr-host.lua" ] || { echo "❌ Failed: hypr-host.lua missing"; rm -rf "$MOCK_HOME"; exit 1; }
    [ -f "$MOCK_HOME/.config/hypr/hypridle.conf" ] || { echo "❌ Failed: hypridle.conf missing"; rm -rf "$MOCK_HOME"; exit 1; }
    [ -f "$MOCK_HOME/.config/hypr/hyprlock.conf" ] || { echo "❌ Failed: hyprlock.conf missing"; rm -rf "$MOCK_HOME"; exit 1; }

    # Verify no broken symlinks inside mock home
    broken_in_mock=$(find "$MOCK_HOME" -xtype l)
    if [ -n "$broken_in_mock" ]; then
        echo "❌ Broken symlinks found in mock deployment for $template:"
        echo "$broken_in_mock"
        rm -rf "$MOCK_HOME"
        exit 1
    fi

    # Cleanup
    rm -rf "$MOCK_HOME"
    echo "  ✅ Template '$template' mock deployment succeeded."
done

echo "  🎉 All template deployments verified cleanly!"
