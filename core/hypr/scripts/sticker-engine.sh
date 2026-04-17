#!/usr/bin/env bash

# 🚀 Pilot HUD — Sticker Vault Engine (v1.3.0)
# Browses and copies local PNG/GIF stickers via Rofi Icons.

VAULT_DIR="$HOME/Pictures/Stickers"
CACHE_DIR="/tmp/pilot-vault"

mkdir -p "$CACHE_DIR"

# Check if vault is empty
if [ -z "$(ls -A "$VAULT_DIR")" ]; then
    notify-send -a "Pilot HUD" "󰞅 Vault Empty" "Drop PNG/GIF files into ~/Pictures/Stickers/ to begin."
    exit 1
fi

# Generate Rofi input with icons
# Format: DisplayName\0icon\x1f/path/to/file
GEN_LIST() {
    for file in "$VAULT_DIR"/*; do
        basename=$(basename "$file")
        echo -en "$basename\0icon\x1f$file\n"
    done
}

SELECTED=$(GEN_LIST | rofi -dmenu -i -p "󰞅 Tactical Vault" -show-icons -theme-str 'listview { columns: 4; }')

if [ -n "$SELECTED" ]; then
    TARGET_FILE="$VAULT_DIR/$SELECTED"
    
    # Detect MIME type
    MIME_TYPE=$(file --mime-type -b "$TARGET_FILE")
    
    # Copy binary to clipboard
    wl-copy --type "$MIME_TYPE" < "$TARGET_FILE"
    
    # Notify Pilot
    notify-send -t 2000 -a "Pilot HUD" "󰞅 Media Captured" "$SELECTED Has been cached for deployment."
fi
