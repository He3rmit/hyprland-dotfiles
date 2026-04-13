#!/bin/bash
# ==============================================================================
# SCRIPT: keybinds-hint.sh [THIN CLIENT]
# PURPOSE: A refined, searchable Tactical Briefing for all HUD keybinds.
#          Sources intelligence from lib-bind-engine.sh and handles display.
# ==============================================================================

# Source the Tactical Intelligence Engine
# Use absolute paths for reliability within Hyprland env
LIB_PATH="$HOME/.config/hypr/scripts/lib-bind-engine.sh"

if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
else
    # Tactical Fallback if lib is missing
    notify-send "Tactical Error" "Briefing Engine Library Not Found" -u critical
    exit 1
fi

# Define Search Paths
GLOBAL_BINDS="$HOME/.config/hypr/modules/keybinds.conf"
USER_BINDS="$HOME/.config/hypr/user-keybinds.conf"

# Generate Briefing and Display
(
    # Fetch data stream from engine and format for Rofi
    parse_bind_file "$GLOBAL_BINDS"
    parse_bind_file "$USER_BINDS"
) | awk -F '\t' '{printf "[%-10s] %-18s 󰁔  %s\n", $1, $2, $3}' | rofi -dmenu -i -p "Tactical Briefing" \
    -theme-str 'window {width: 1000px; height: 600px;} 
                listview {columns: 1; lines: 15; spacing: 8px; scrollbar: true;} 
                element {padding: 8px 12px;} 
                element-text {font: "ShureTechMono Nerd Font 14";}'
