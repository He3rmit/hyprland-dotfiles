#!/usr/bin/env bash

# --- TITAN CONFIGURATION ---
# The file that holds the state
STATE_FILE="$HOME/.config/hypr/touchpad.lua"

# Auto-detect or load cached touchpad device name & state
DEVICE=""
CURR_STATE=""

if [[ -f "$STATE_FILE" ]]; then
    while IFS= read -r line; do
        if [[ "$line" =~ name[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
            DEVICE="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ enabled[[:space:]]*=[[:space:]]*(true|false) ]]; then
            CURR_STATE="${BASH_REMATCH[1]}"
        fi
    done < "$STATE_FILE"
fi

# Fallback: Single-pass hardware discovery if state file is missing or invalid
if [ -z "$DEVICE" ]; then
    DEVICE=$(hyprctl devices -j 2>/dev/null | jq -r '.mice[] | select(.name | test("touchpad|synaptics|asif|elan|asue"; "i")) | .name' | head -1)
fi

if [ -z "$DEVICE" ]; then
    notify-send -u low -i input-touchpad-off "Touchpad" "No touchpad device detected"
    exit 0
fi

# Check if currently disabled
if [[ "$CURR_STATE" == "false" ]]; then
    # TOGGLE ON: Enable it
    echo "hl.device({
    name = \"$DEVICE\",
    enabled = true
})" > "$STATE_FILE"
    hyprctl eval "hl.device({ name = \"$DEVICE\", enabled = true })"
    notify-send -u low -i input-touchpad-on "Touchpad" "Enabled ✅"
else
    # TOGGLE OFF: Disable it
    echo "hl.device({
    name = \"$DEVICE\",
    enabled = false
})" > "$STATE_FILE"
    hyprctl eval "hl.device({ name = \"$DEVICE\", enabled = false })"
    notify-send -u low -i input-touchpad-off "Touchpad" "Disabled 🚫"
fi