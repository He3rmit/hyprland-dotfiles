#!/usr/bin/env bash

# 🚀 Pilot HUD — Klipy GIF Engine (Gen 2: Optical Hub)
# High-fidelity Live Search with Visual Previews.

# Tactical Calibration
CACHE_DIR="/tmp/pilot-vault"
SECRETS_FILE="$HOME/.secrets.sh"

# Load OPSEC Secrets
if [ -f "$SECRETS_FILE" ]; then
    source "$SECRETS_FILE"
else
    notify-send -t 5000 -i "dialog-information" -a "Pilot HUD" "󰞅 Secrets Missing" "Setup required: cp ~/dotfiles/home/.secrets.sh.example ~/.secrets.sh"
    exit 1
fi

# Klipy API Key Check
if [ -z "$KLIPY_API_KEY" ]; then
    notify-send -t 5000 -i "dialog-warning" -a "Pilot HUD" "󰞅 API Key Missing" "Edit ~/.secrets.sh to add your Klipy API key."
    exit 1
fi

mkdir -p "$CACHE_DIR"
rm -rf "$CACHE_DIR"/* # Clear old scans

# Step 1: Initial Infiltration (Search Input)
SEARCH_TERM=$(rofi -dmenu -i -p "󱗗 Klipy Infiltration" -theme-str 'listview { columns: 1; }')

if [ -z "$SEARCH_TERM" ]; then exit 0; fi

notify-send -t 2000 -a "Pilot HUD" "󱗗 Discovery Active" "Scanning Klipy archives for: $SEARCH_TERM..."

# Step 2: Query API & Parse Optics
SEARCH_URL="https://api.klipy.co/v1/search?q=${SEARCH_TERM// /+}&key=$KLIPY_API_KEY&limit=16"
RESPONSE=$(curl -s "$SEARCH_URL")

# Extract URLs via jq. Klipy uses .files[].gif.url (or preview_url)
# We fetch 'tinygif' for thumbnails and 'gif' for the final payload.
RESULTS=$(echo "$RESPONSE" | jq -r '.results[] | "\(.files.tinygif.url)|\(.files.gif.url)|\(.id)"')

if [ -z "$RESULTS" ]; then
    notify-send -a "Pilot HUD" "󰞅 Zero Signal" "No results found for your query."
    exit 1
fi

# Step 3: Parallel Optical Capture (Download Thumbnails)
index=0
declare -A PAYLOAD_MAP
while IFS='|' read -r thumb_url full_url id; do
    thumb_path="$CACHE_DIR/${id}.gif"
    # Download thumbnail in background
    curl -s "$thumb_url" -o "$thumb_path" &
    
    # Map the id to the full url for later retrieval
    PAYLOAD_MAP["$id"]="$full_url"
    ((index++))
done <<< "$RESULTS"

# Wait for essential thumbnails (first 4) to ensure responsive launch
wait

# Step 4: Launch Optical Hub (Icon Discovery)
GEN_LIST() {
    for id in "${!PAYLOAD_MAP[@]}"; do
        echo -en "GIF-$id\0icon\x1f$CACHE_DIR/${id}.gif\n"
    done
}

SELECTED_ENTRY=$(GEN_LIST | rofi -dmenu -i -p "󰞅 Select Payload" -show-icons -theme-str 'listview { columns: 4; lines: 4; }')

if [ -n "$SELECTED_ENTRY" ]; then
    # Extract ID from "GIF-id"
    SELECTED_ID=$(echo "$SELECTED_ENTRY" | sed 's/GIF-//')
    FULL_URL="${PAYLOAD_MAP[$SELECTED_ID]}"
    
    notify-send -t 2000 -a "Pilot HUD" "󰞅 Capturing" "Downloading full-resolution payload..."
    
    # Download full resolution GIF to cache
    FINAL_PATH="$CACHE_DIR/final_${SELECTED_ID}.gif"
    curl -s "$FULL_URL" -o "$FINAL_PATH"
    
    # Copy to Clipboard (MIME: image/gif)
    wl-copy --type image/gif < "$FINAL_PATH"
    
    # Notify Post-Deployment
    notify-send -t 2000 -a "Pilot HUD" "󰞅 Target Locked" "GIF Has been cached for deployment (Ctrl+V)."
fi
