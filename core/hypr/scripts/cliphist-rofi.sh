#!/bin/bash
# -----------------------------------------------------
# Titanfall Clipboard Manager (Pilot Edition)
# -----------------------------------------------------

THEME="$HOME/.config/rofi/themes/clipboard.rasi"
CACHE_DIR="/tmp/cliphist-thumbnails"
mkdir -p "$CACHE_DIR"

# Keybind cheat sheet shown at the bottom of the popup
KEYBIND_HINTS="Enter: Paste  |  Alt+P: Preview  |  Alt+Del: Delete | Shift+Enter: Select Items |  Alt+Shift+Del: Wipe  |  Alt+T: Type  |  Alt+O: URL  |  Alt+E: Edit"

notify_pilot() {
    notify-send -u normal -a "Titanfall Systems" -i "terminal" "$1" "$2"
}

generate_list() {
    local img_count=0
    cliphist list | head -n 150 | while IFS= read -r line; do
        # Extract ID and Content instantaneously using bash native substring splitting
        id="${line%%$'\t'*}"
        content="${line#*$'\t'}"
        
        if [[ "$content" =~ binary.*data ]] || [[ "$content" =~ file://.* ]]; then
            # Extract path if it's a URI, otherwise use ID for binary
            if [[ "$content" =~ file://(.*) ]]; then
                raw_path="${BASH_REMATCH[1]}"
                # Ensure we handle spaces/special chars in URI
                image_source=$(echo -e "${raw_path//%/\\x}")
                preview_file="$CACHE_DIR/uri_$(echo -n "$image_source" | md5sum | cut -d' ' -f1).png"
                label="[File: $(basename "$image_source")]"
            else
                image_source="-" # Read from stdin (cliphist decode)
                preview_file="$CACHE_DIR/${id}.png"
                
                # Extract dimensions directly from cliphist output
                if [[ "$content" =~ ([0-9]+x[0-9]+) ]]; then
                    label="[Bin: ${BASH_REMATCH[1]}]"
                else
                    label="[Binary Image]"
                fi
            fi

            if [ ! -f "$preview_file" ]; then
                # Performance Throttle: Only spawn background magick for first 20 images
                if [ $img_count -lt 20 ]; then
                    img_count=$((img_count + 1))
                    if [ "$image_source" == "-" ]; then
                        (cliphist decode "$id" | magick - -resize '64x64^' -gravity center -extent 64x64 "$preview_file" >/dev/null 2>&1) &
                    else
                        (magick "$image_source"[0] -resize '64x64^' -gravity center -extent 64x64 "$preview_file" >/dev/null 2>&1) &
                    fi
                fi
            fi
            
            echo -en "${id}\t${label}\0icon\x1f${preview_file}\n"
        else
            # Clean string purely in bash (no slow sub-processes)
            # Remove any extra spacing
            clean="${content//  / }"
            clean="${clean//  / }"
            echo -en "${id}\t${clean:0:120}\0icon\x1ftext-x-generic\n"
        fi
    done
}

# Kill Rofi if already running
if pgrep -x "rofi" > /dev/null; then
    pkill rofi
    exit 0
fi

selection=$(generate_list | rofi -dmenu \
    -theme "$THEME" \
    -p "󰅇" \
    -mesg "$KEYBIND_HINTS" \
    -display-columns 2 \
    -show-icons \
    -multi-select "Shift+Enter" \
    -kb-custom-1 "Alt+Delete" \
    -kb-custom-2 "Alt+Shift+Delete" \
    -kb-custom-3 "Alt+t" \
    -kb-custom-4 "Alt+o" \
    -kb-custom-5 "Alt+e" \
    -kb-custom-6 "Alt+p")

exit_code=$?
[ -z "$selection" ] && exit 0
clip_ids=$(echo "$selection" | awk '{print $1}')

case $exit_code in
    0)  # ENTER — Paste (First item only)
        first_id=$(echo "$clip_ids" | head -n 1)
        
        # 1. Peek at the data to determine handling
        # We use a subshell to avoid double-decoding if possible for small items
        raw_data=$(cliphist decode "$first_id" 2>/dev/null)
        
        if [[ "$raw_data" == file://* ]]; then
            # Re-copy as text/uri-list so apps treat it as a file upload
            # CLEAN: Remove trailing carriage returns (\r) which break paths
            clean_uri="${raw_data%$'\r'}"
            echo -n "$clean_uri" | wl-copy --type text/uri-list
        else
            # It's binary or raw text. Detect the MIME type for maximum compatibility.
            mime_type=$(cliphist decode "$first_id" | file -b --mime-type -)
            
            if [[ "$mime_type" == image/* ]]; then
                # Explicitly set the image type so Discord/Telegram recognize it immediately
                cliphist decode "$first_id" | wl-copy --type "$mime_type"
            else
                # Standard text handling
                cliphist decode "$first_id" | wl-copy
            fi
        fi
        notify_pilot "Buffer Updated" "Data sequence ready."
        ;;
    15) # Alt+P — Preview Image (First item only)
        first_id=$(echo "$clip_ids" | head -n 1)
        tmp_img="$CACHE_DIR/preview_$first_id.png"
        cliphist decode "$first_id" > "$tmp_img"
        xdg-open "$tmp_img" &
        notify_pilot "Visual Feed Active" "Opening image preview..."
        ;;
    10) # Alt+Delete — Delete Entry (Deep Purge)
        echo "$clip_ids" | while read -r id; do
            # Decode the real content (not the synthetic label rofi returns)
            decoded=$(cliphist decode "$id" 2>/dev/null)
            # If it's a Hydra cache URI, shred the physical file
            if [[ "$decoded" =~ ^file://(.+/.cache/pilot-hydra/ck_[^[:space:]]+) ]]; then
                rm -f "${BASH_REMATCH[1]}"
            fi
            # Fetch the real cliphist list line by ID and pipe to delete
            cliphist list | awk -F'\t' -v id="$id" '$1 == id { print; exit }' | cliphist delete
        done
        notify_pilot "Entry Purged" "Clipboard item and cache file removed."
        ;;
    11) # Alt+Shift+Delete — Wipe All (Nuke)
        cliphist wipe
        rm -rf "$CACHE_DIR"/*
        rm -rf "$HOME/.cache/pilot-hydra"/*
        notify-send -u critical -a "Titanfall Systems" "DATABASE PURGED" "History and Hydra Cache erased."
        ;;
    12) # Alt+T — Auto-Type
        echo "$clip_ids" | while read -r id; do
            cliphist decode "$id" | wtype -
            sleep 0.1 # small pause between consecutive bulk pastes
        done
        ;;
    13) # Alt+O — Open URL
        echo "$clip_ids" | while read -r id; do
            url=$(cliphist decode "$id")
            notify_pilot "Opening Uplink" "$url"
            xdg-open "$url" &
        done
        ;;
    14) # Alt+E — Edit in Terminal
        tmp_file="/tmp/cliphist-edit-$$.txt"
        > "$tmp_file"
        echo "$clip_ids" | while read -r id; do
            cliphist decode "$id" >> "$tmp_file"
            echo "" >> "$tmp_file" # separator
        done
        notify_pilot "Editing Multi-Record" "Opening secure editor..."
        kitty --class floating -e nano "$tmp_file"
        if [ -s "$tmp_file" ]; then
            cat "$tmp_file" | wl-copy
            rm "$tmp_file"
            notify_pilot "Buffer Updated" "Combined custom string saved to clipboard."
        fi
        ;;
esac