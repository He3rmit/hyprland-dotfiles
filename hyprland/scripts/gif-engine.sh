#!/usr/bin/env bash

# 🚀 Pilot HUD — GIF Engine (Gen 2: Optical Hub)
# High-fidelity Live Search with Visual Previews (Giphy / Klipy)

set -euo pipefail
umask 077

SECRETS_FILE="$HOME/.secrets.sh"

# Load OPSEC Secrets
if [ -f "$SECRETS_FILE" ]; then
    source "$SECRETS_FILE"
else
    notify-send -t 5000 -i "dialog-information" -a "Pilot HUD" "󰞅 Secrets Missing" "Setup required: cp ~/dotfiles/home/.secrets.sh.example ~/.secrets.sh"
    exit 1
fi

KLIPY_API_KEY="${KLIPY_API_KEY:-}"
GIPHY_API_KEY="${GIPHY_API_KEY:-}"

if [[ -z "$KLIPY_API_KEY" && -z "$GIPHY_API_KEY" ]]; then
    notify-send -t 5000 -i "dialog-warning" -a "Pilot HUD" "󰞅 API Key Missing" "Edit ~/.secrets.sh to add your GIPHY or KLIPY API key."
    exit 1
fi

# Secure Cache Directory (Private)
CACHE_DIR="$(mktemp -d --tmpdir pilot-vault.XXXXXX)"
chmod 700 "$CACHE_DIR"
trap 'rm -rf "$CACHE_DIR"' EXIT

# Step 1: Initial Infiltration (Search Input)
SEARCH_TERM=$(rofi -dmenu -i -p "󱗗 GIF Discovery" -theme-str 'listview { columns: 1; }')
if [ -z "$SEARCH_TERM" ]; then exit 0; fi

notify-send -t 2000 -a "Pilot HUD" "󱗗 Discovery Active" "Scanning archives for: $SEARCH_TERM..."

# URL Encode the search term securely
SAFE_TERM=$(jq -sRr @uri <<< "$SEARCH_TERM")

# Determine Provider and URL
AUTH_FILE="$(mktemp)"
chmod 600 "$AUTH_FILE"

if [[ -n "$GIPHY_API_KEY" ]]; then
    PROVIDER="GIPHY"
    printf 'url = "https://api.giphy.com/v1/gifs/search?q=%s&api_key=%s&limit=16"\n' "$SAFE_TERM" "$GIPHY_API_KEY" > "$AUTH_FILE"
else
    PROVIDER="KLIPY"
    printf 'url = "https://api.klipy.co/v1/search?q=%s&key=%s&limit=16"\n' "$SAFE_TERM" "$KLIPY_API_KEY" > "$AUTH_FILE"
fi

# Step 2: Query API securely (hiding key from 'ps')
RESPONSE=$(curl -sS --fail --config "$AUTH_FILE" || true)
rm -f "$AUTH_FILE"

if [ -z "$RESPONSE" ]; then
    notify-send -a "Pilot HUD" "󰞅 Zero Signal" "API fetch failed or no results found."
    exit 1
fi

# Extract URLs via jq based on provider
if [[ "$PROVIDER" == "GIPHY" ]]; then
    RESULTS=$(echo "$RESPONSE" | jq -r '.data[] | "\(.images.fixed_width_small.url)|\(.images.original.url)|\(.id)"')
else
    RESULTS=$(echo "$RESPONSE" | jq -r '.results[] | "\(.files.tinygif.url)|\(.files.gif.url)|\(.id)"')
fi

if [ -z "$RESULTS" ]; then
    notify-send -a "Pilot HUD" "󰞅 Zero Signal" "No results found for your query."
    exit 1
fi

# Step 3: Optical Capture (Download Thumbnails)
index=0
declare -A PAYLOAD_MAP
declare -a BG_PIDS

while IFS='|' read -r thumb_url full_url id; do
    # Sanitize ID against path traversal
    safe_id="$(printf '%s' "$id" | tr -cd 'A-Za-z0-9_-')"
    [[ -n "$safe_id" ]] || continue
    
    thumb_path="$CACHE_DIR/${safe_id}.gif"
    
    # Download thumbnail in background with constraints
    curl -sS --fail --max-time 10 "$thumb_url" -o "$thumb_path" &
    BG_PIDS+=($!)
    
    PAYLOAD_MAP["$safe_id"]="$full_url"
    ((index++))
    
    # Bound parallel downloads to avoid network spikes (download first 4 synchronously-ish)
    if [[ $index -eq 4 ]]; then
        for pid in "${BG_PIDS[@]}"; do wait "$pid" || true; done
        BG_PIDS=()
    fi
done <<< "$RESULTS"

# Wait for remaining background thumbnails
for pid in "${BG_PIDS[@]}"; do wait "$pid" || true; done

# Step 4: Launch Optical Hub (Icon Discovery)
GEN_LIST() {
    for id in "${!PAYLOAD_MAP[@]}"; do
        if [[ -f "$CACHE_DIR/${id}.gif" ]]; then
            echo -en "GIF-$id\0icon\x1f$CACHE_DIR/${id}.gif\n"
        fi
    done
}

SELECTED_ENTRY=$(GEN_LIST | rofi -dmenu -i -p "󰞅 Select Payload" -show-icons -theme-str 'listview { columns: 4; lines: 4; }')

if [ -n "$SELECTED_ENTRY" ]; then
    SELECTED_ID=$(echo "$SELECTED_ENTRY" | sed 's/GIF-//')
    FULL_URL="${PAYLOAD_MAP[$SELECTED_ID]}"
    
    notify-send -t 2000 -a "Pilot HUD" "󰞅 Capturing" "Downloading full-resolution payload..."
    
    FINAL_PATH="$CACHE_DIR/final_${SELECTED_ID}.gif"
    
    # Strict curl download with constraints
    curl -sS --fail \
        --proto '=https' --tlsv1.2 \
        --max-time 20 --connect-timeout 5 \
        --max-filesize 15M \
        -L --retry 2 \
        "$FULL_URL" -o "$FINAL_PATH" || {
        notify-send -t 3000 -a "Pilot HUD" "❌ Error" "Download failed or file too large."
        exit 1
    }
    
    # Verify MIME type
    file_out="$(file -b --mime-type "$FINAL_PATH" || true)"
    if [[ "$file_out" != "image/gif" && "$file_out" != "image/webp" ]]; then
        notify-send -t 3000 -a "Pilot HUD" "❌ Error" "Invalid file format detected ($file_out)."
        exit 1
    fi
    
    # Copy to Clipboard
    wl-copy --type "$file_out" < "$FINAL_PATH"
    notify-send -t 2000 -a "Pilot HUD" "󰞅 Target Locked" "GIF Has been cached for deployment (Ctrl+V)."
fi
