#!/usr/bin/env bash

# ==============================================================================
# MIRROR HOTPLUG — Auto-Detect External Displays
# Cycles through: Laptop Only → External Only → Extend → Mirror
# ==============================================================================

STATE_FILE="/tmp/hypr-display-state"

# --- AUTO-DETECT ---
# Find the built-in display (eDP or LVDS)
LAPTOP=$(hyprctl monitors all -j | jq -r '.[] | select(.name | test("^eDP|^LVDS")) | .name' | head -1)

# Find the first external display (HDMI, DP, etc.)
EXTERNAL=$(hyprctl monitors all -j | jq -r '.[] | select(.name | test("^eDP|^LVDS") | not) | .name' | head -1)

# --- SAFETY CHECK ---
if [ -z "$LAPTOP" ]; then
    notify-send -u normal "Display" "No built-in display detected. This script is for laptops."
    exit 1
fi

# --- HELPER FUNCTIONS (Lua eval with legacy keyword fallback) ---
set_monitor() {
    local output="$1"
    local mode="${2:-preferred}"
    local pos="${3:-auto}"
    local scale="${4:-1}"
    local mirror="$5"

    if [ -n "$mirror" ]; then
        if ! hyprctl eval "hl.monitor({ output = \"$output\", mode = \"$mode\", position = \"$pos\", scale = $scale, mirror = \"$mirror\" })" 2>&1 | grep -q "ok"; then
            hyprctl keyword monitor "$output, $mode, $pos, $scale, mirror, $mirror" 2>/dev/null
        fi
    else
        if ! hyprctl eval "hl.monitor({ output = \"$output\", mode = \"$mode\", position = \"$pos\", scale = $scale })" 2>&1 | grep -q "ok"; then
            hyprctl keyword monitor "$output, $mode, $pos, $scale" 2>/dev/null
        fi
    fi
}

disable_monitor() {
    local output="$1"
    if ! hyprctl eval "hl.monitor({ output = \"$output\", disabled = true })" 2>&1 | grep -q "ok"; then
        hyprctl keyword monitor "$output, disable" 2>/dev/null
    fi
}

if [ -z "$EXTERNAL" ]; then
    notify-send -u normal "Display" "No external monitor detected. Plug one in first."
    # Ensure laptop display is on
    set_monitor "$LAPTOP" "preferred" "auto" "1"
    echo "0" > "$STATE_FILE"
    exit 1
fi

# --- STATE LOGIC ---
if [ ! -f "$STATE_FILE" ]; then
    echo "0" > "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")
NEXT_MODE=$(( (STATE + 1) % 4 ))

# --- EXECUTION ---
case $NEXT_MODE in
    0)
        notify-send -t 2000 "Display" "💻 Mode: Laptop Only"
        set_monitor "$LAPTOP" "preferred" "auto" "1"
        disable_monitor "$EXTERNAL"
        ;;
    1)
        notify-send -t 2000 "Display" "📺 Mode: External Only"
        disable_monitor "$LAPTOP"
        set_monitor "$EXTERNAL" "preferred" "auto" "1"
        ;;
    2)
        notify-send -t 2000 "Display" "↔️ Mode: Extend (Dual Monitor)"
        set_monitor "$LAPTOP" "preferred" "auto" "1"
        set_monitor "$EXTERNAL" "preferred" "auto-right" "1"
        ;;
    3)
        notify-send -t 2000 "Display" "🪞 Mode: Mirror (Presentation)"
        set_monitor "$LAPTOP" "preferred" "auto" "1"
        set_monitor "$EXTERNAL" "preferred" "auto" "1" "$LAPTOP"
        ;;
esac

echo "$NEXT_MODE" > "$STATE_FILE"