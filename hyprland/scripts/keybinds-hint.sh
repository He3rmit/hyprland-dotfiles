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
GLOBAL_BINDS="$HOME/.config/hypr/modules/keybinds.lua"
HOST_BINDS="$HOME/.config/hypr/host.lua"
USER_BINDS="$HOME/.config/hypr/user-keybinds.lua"

# Generate Briefing and Display
raw_list=$(
    parse_bind_file "$GLOBAL_BINDS"
    parse_bind_file "$HOST_BINDS"
    parse_bind_file "$USER_BINDS"
    print_bind_list
)

# Format and pipe to Rofi in a single high-performance awk pass
echo "$raw_list" | awk -F '\t' 'BEGIN {c_max=10; k_max=16; count=0} {
    c[count] = $1; k[count] = $2; d[count] = $3
    if (length($1) > c_max) c_max = length($1)
    if (length($2) > k_max) k_max = length($2)
    count++
} END {
    fmt = sprintf("[%%-%ds] %%-%ds 󰁔  %%s\n", c_max, k_max)
    for (i = 0; i < count; i++) {
        printf fmt, c[i], k[i], d[i]
    }
}' | rofi -dmenu -i -p "Tactical Briefing" \
    -theme-str 'window {width: 1000px; height: 600px;} 
                listview {columns: 1; lines: 15; spacing: 8px; scrollbar: true;} 
                element {padding: 8px 12px;} 
                element-text {font: "ShureTechMono Nerd Font 14";}'
