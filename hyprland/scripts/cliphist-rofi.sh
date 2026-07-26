#!/bin/bash
# -----------------------------------------------------
# Titanfall Clipboard Manager (Pilot Edition)
# -----------------------------------------------------

THEME="$HOME/.config/rofi/themes/clipboard.rasi"
CACHE_DIR="$HOME/.cache/cliphist-thumbnails"
mkdir -p "$CACHE_DIR"

# Prevent ImageMagick from hogging all CPU cores & RAM
export MAGICK_THREAD_LIMIT=1
export MAGICK_MEMORY_LIMIT=32MiB
export MAGICK_TIME_LIMIT=2

# Cleanup old thumbnail cache files (older than 3 days) in background
(find "$CACHE_DIR" -type f -mtime +3 -delete 2>/dev/null) &

# Keybind cheat sheet shown at the bottom of the popup
KEYBIND_HINTS="Enter: Paste  |  Alt+P: Preview  |  Alt+Del: Delete | Shift+Enter: Select Items |  Alt+Shift+Del: Wipe  |  Alt+T: Type  |  Alt+O: URL  |  Alt+E: Edit"

notify_pilot() {
    notify-send -u normal -a "Titanfall Systems" -i "terminal" "$1" "$2"
}

generate_list() {
    local img_count=0
    cliphist list | head -n 150 | while IFS= read -r line; do
        id="${line%%$'\t'*}"
        content="${line#*$'\t'}"
        
        # Detect file paths or file URIs
        file_path=""
        if [[ "$content" =~ file://(.*) ]]; then
            file_path=$(echo -e "${BASH_REMATCH[1]//%/\\x}")
            file_path="${file_path%$'\r'}"
        elif [[ "$content" =~ ^(/[^[:space:]]+) ]] && [ -f "${BASH_REMATCH[1]}" ]; then
            file_path="${BASH_REMATCH[1]}"
        fi

        if [ -n "$file_path" ] && [ -f "$file_path" ]; then
            filename="${file_path##*/}"
            clean_hash="${file_path//[\/ %]/_}"
            preview_file="$CACHE_DIR/uri_${clean_hash: -32}.png"
            ext="${file_path##*.}"
            ext_lc=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

            case "$ext_lc" in
                mp4|mkv|webm|avi|mov|flv|wmv)
                    label="[Video: ${filename}]"
                    if [ ! -f "$preview_file" ] && [ $img_count -lt 5 ]; then
                        img_count=$((img_count + 1))
                        (nice -n 19 ffmpegthumbnailer -i "$file_path" -o "$preview_file" -s 64 >/dev/null 2>&1) &
                    fi
                    icon_val="$preview_file"
                    [ ! -f "$preview_file" ] && icon_val="video-x-generic"
                    ;;
                png|jpg|jpeg|gif|webp)
                    label="[Image: ${filename}]"
                    if [ ! -f "$preview_file" ] && [ $img_count -lt 5 ]; then
                        img_count=$((img_count + 1))
                        (nice -n 19 magick "$file_path"[0] -resize '64x64^' -gravity center -extent 64x64 "$preview_file" >/dev/null 2>&1) &
                    fi
                    icon_val="$preview_file"
                    [ ! -f "$preview_file" ] && icon_val="image-x-generic"
                    ;;
                *)
                    label="[File: ${filename}]"
                    icon_val="text-x-generic"
                    ;;
            esac

            echo -en "${id}\t${label}\0icon\x1f${icon_val}\n"

        elif [[ "$content" =~ binary.*data ]]; then
            preview_file="$CACHE_DIR/${id}.png"
            if [[ "$content" =~ ([0-9]+x[0-9]+) ]]; then
                label="[Bin: ${BASH_REMATCH[1]}]"
            else
                label="[Binary Image]"
            fi

            if [ ! -f "$preview_file" ] && [ $img_count -lt 5 ]; then
                img_count=$((img_count + 1))
                (nice -n 19 cliphist decode "$id" | nice -n 19 magick - -resize '64x64^' -gravity center -extent 64x64 "$preview_file" >/dev/null 2>&1) &
            fi

            echo -en "${id}\t${label}\0icon\x1f${preview_file}\n"
        else
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
        
        raw_data=$(cliphist decode "$first_id" 2>/dev/null)
        clean_data="${raw_data%$'\r'}"

        target_path=""
        if [[ "$clean_data" == file://* ]]; then
            raw_path="${clean_data#file://}"
            target_path=$(echo -e "${raw_path//%/\\x}")
        elif [[ "$clean_data" =~ ^(/[^[:space:]]+) ]] && [ -f "${BASH_REMATCH[1]}" ]; then
            target_path="${BASH_REMATCH[1]}"
        fi

        if [ -n "$target_path" ] && [ -f "$target_path" ]; then
            # Convert file path to file:// URI so Discord, Telegram, Browsers treat it as an actual file attachment!
            encoded_path=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$target_path")
            file_uri="file://${encoded_path}"
            echo -n "$file_uri" | wl-copy --type text/uri-list
        else
            mime_type=$(cliphist decode "$first_id" | file -b --mime-type -)
            if [[ "$mime_type" == image/* ]]; then
                cliphist decode "$first_id" | wl-copy --type "$mime_type"
            else
                cliphist decode "$first_id" | wl-copy
            fi
        fi

        # Auto-paste into active window
        (sleep 0.15 && wtype -M ctrl -k v -m ctrl) &

        notify_pilot "Buffer Updated" "Pasted into active window."
        ;;
    15) # Alt+P — Preview / Open Media (First item only)
        first_id=$(echo "$clip_ids" | head -n 1)
        raw_data=$(cliphist decode "$first_id" 2>/dev/null)
        clean_data="${raw_data%$'\r'}"

        target_path=""
        if [[ "$clean_data" == file://* ]]; then
            raw_path="${clean_data#file://}"
            target_path=$(echo -e "${raw_path//%/\\x}")
        elif [[ "$clean_data" =~ ^(/[^[:space:]]+) ]] && [ -f "${BASH_REMATCH[1]}" ]; then
            target_path="${BASH_REMATCH[1]}"
        fi

        if [ -n "$target_path" ] && [ -f "$target_path" ]; then
            # Direct file preview (videos open in default video player, images in viewer)
            xdg-open "$target_path" &
            notify_pilot "Visual Feed Active" "Opening $(basename "$target_path")..."
        elif [[ "$clean_data" =~ ^https?:// ]]; then
            # Web URL preview
            xdg-open "$clean_data" &
            notify_pilot "Uplink Active" "Opening URL in browser..."
        else
            # Binary image or raw text
            mime_type=$(cliphist decode "$first_id" | file -b --mime-type -)
            if [[ "$mime_type" == image/* ]]; then
                tmp_img="$CACHE_DIR/preview_${first_id}.png"
                cliphist decode "$first_id" > "$tmp_img"
                xdg-open "$tmp_img" &
                notify_pilot "Visual Feed Active" "Opening image preview..."
            else
                # Text preview in notification
                notify_pilot "Text Preview" "${clean_data:0:300}"
            fi
        fi
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