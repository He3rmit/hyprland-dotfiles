#!/usr/bin/env bash

# 🚀 Pilot HUD — Hydra Media Hub (v1.3.0)
# Unified high-fidelity dispatcher for Emojis, GIFs, and Stickers.

SCRIPTS_DIR="$HOME/.config/hypr/scripts"

# Modular Navigation
declare -A MODES
MODES=(
    ["󰞅  EMOJI"]="$SCRIPTS_DIR/emoji-engine.sh"
    ["󱗗  GIF"]="$SCRIPTS_DIR/gif-engine.sh"
    ["󰞅  STICKERS"]="$SCRIPTS_DIR/sticker-engine.sh"
)

# Build Rofi menu
MENU=""
for mode in "${!MODES[@]}"; do
    MENU+="$mode\n"
done

# Launch Dispatcher
SELECTED=$(echo -e "$MENU" | rofi -dmenu -i -p "󰞅 Tactical Hydra" -theme-str 'listview { lines: 3; }')

if [ -n "$SELECTED" ]; then
    # Execute the selected engine
    ${MODES[$SELECTED]}
fi
