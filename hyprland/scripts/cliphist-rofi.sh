#!/bin/bash
# -----------------------------------------------------
# Titanfall Clipboard Manager (Pilot Edition)
# -----------------------------------------------------

THEME="$HOME/.config/rofi/themes/clipboard.rasi"
CACHE_DIR="$HOME/.cache/cliphist-thumbnails"
mkdir -p "$CACHE_DIR"

# Prevent ImageMagick from hogging CPU cores & RAM
export MAGICK_THREAD_LIMIT=1
export MAGICK_MEMORY_LIMIT=64MiB
export MAGICK_TIME_LIMIT=3

# Cleanup thumbnail cache files older than 3 days in background
(find "$CACHE_DIR" -type f -mtime +3 -delete 2>/dev/null) &

# Keybind cheat sheet shown at the bottom of the popup
KEYBIND_HINTS="Enter: Paste  |  Shift+Enter: Multi-Select  |  Alt+P: Preview  |  Alt+E: Edit  |  Alt+O: URL  |  Alt+T: Type  |  Alt+Del: Delete  |  Alt+Shift+Del: Wipe"

notify_pilot() {
    notify-send -u normal -a "Titanfall Systems" -i "terminal" "$1" "$2"
}

generate_list() {
    local img_count=0
    cliphist list | head -n 150 | while IFS=$'\t' read -r id content; do
        
        # Detect file paths or file URIs (including paths containing spaces)
        file_path=""
        clean_content="${content%$'\r'}"
        if [[ "$content" =~ file://(.*) ]]; then
            file_path=$(echo -e "${BASH_REMATCH[1]//%/\\x}")
            file_path="${file_path%$'\r'}"
        elif [[ "$clean_content" == /* ]] && [ -f "$clean_content" ]; then
            file_path="$clean_content"
        fi

        if [ -n "$file_path" ] && [ -f "$file_path" ]; then
            filename="${file_path##*/}"
            clean_hash="${file_path//[\/ %]/_}"
            preview_file="$CACHE_DIR/uri_${clean_hash: -32}.png"
            ext="${file_path##*.}"
            ext_lc=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

            case "$ext_lc" in
                mp4|mkv|webm|avi|mov|flv|wmv)
                    label="󰕧 Video • ${filename}"
                    if [ ! -f "$preview_file" ] && [ $img_count -lt 25 ]; then
                        img_count=$((img_count + 1))
                        (nice -n 19 ffmpegthumbnailer -i "$file_path" -o "$preview_file" -s 160 >/dev/null 2>&1) &
                    fi
                    icon_val="$preview_file"
                    [ ! -f "$preview_file" ] && icon_val="video-x-generic"
                    ;;
                png|jpg|jpeg|gif|webp|svg)
                    label="󰈟 Image • ${filename}"
                    if [ ! -f "$preview_file" ] && [ $img_count -lt 25 ]; then
                        img_count=$((img_count + 1))
                        (nice -n 19 magick "$file_path"[0] -resize '160x90>' -background '#0a0f14' -gravity center -extent 160x90 "$preview_file" >/dev/null 2>&1) &
                    fi
                    icon_val="$preview_file"
                    [ ! -f "$preview_file" ] && icon_val="image-x-generic"
                    ;;
                mp3|flac|wav|ogg|m4a)
                    label="󰎈 Audio • ${filename}"
                    icon_val="audio-x-generic"
                    ;;
                pdf|doc|docx|odt|epub)
                    label="󰈙 Document • ${filename}"
                    icon_val="x-office-document"
                    ;;
                *)
                    label="󰈔 File • ${filename}"
                    icon_val="text-x-generic"
                    ;;
            esac

            echo -en "${id}\t${label}\0icon\x1f${icon_val}\n"

        elif [[ "$content" =~ binary.*data ]]; then
            preview_file="$CACHE_DIR/${id}.png"
            
            # Extract resolution and size if provided by cliphist
            res=""
            bsize=""
            if [[ "$content" =~ ([0-9]+x[0-9]+) ]]; then
                res="${BASH_REMATCH[1]}"
            fi
            if [[ "$content" =~ ([0-9]+(\.[0-9]+)?\ [KMG]?i?B) ]]; then
                bsize="${BASH_REMATCH[1]}"
            fi

            if [ -n "$res" ] && [ -n "$bsize" ]; then
                label="󰹑 Screenshot • ${res} (${bsize})"
            elif [ -n "$res" ]; then
                label="󰹑 Screenshot • ${res}"
            elif [ -n "$bsize" ]; then
                label="󰋩 Image Clip • ${bsize}"
            else
                label="󰋩 Image Clip"
            fi

            if [ ! -f "$preview_file" ] && [ $img_count -lt 25 ]; then
                img_count=$((img_count + 1))
                (nice -n 19 cliphist decode "$id" | nice -n 19 magick - -resize '160x90>' -background '#0a0f14' -gravity center -extent 160x90 "$preview_file" >/dev/null 2>&1) &
            fi

            echo -en "${id}\t${label}\0icon\x1f${preview_file}\n"

        else
            clean="${content//  / }"
            clean="${clean//  / }"
            # Fast pure-bash whitespace trimming (no subshell, no quote escaping issues)
            trimmed="${clean#"${clean%%[![:space:]]*}"}"
            trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

            # Hex color code swatch detection (#ffffff, #1a1a24ff)
            if [[ "$trimmed" =~ ^#[0-9a-fA-F]{6}$ ]] || [[ "$trimmed" =~ ^#[0-9a-fA-F]{8}$ ]]; then
                label="󰏘 Hex Color • ${trimmed}"
                swatch_file="$CACHE_DIR/color_${trimmed#\#}.png"
                if [ ! -f "$swatch_file" ]; then
                    (nice -n 19 magick -size 80x80 xc:"$trimmed" -bordercolor '#ffffff33' -border 2 "$swatch_file" >/dev/null 2>&1) &
                fi
                echo -en "${id}\t${label}\0icon\x1f${swatch_file}\n"

            # URL / Web link detection
            elif [[ "$trimmed" =~ ^https?:// ]]; then
                label="󰌹 ${clean:0:110}"
                echo -en "${id}\t${label}\0icon\x1fapplications-internet\n"

            # Shell commands and code blocks detection
            elif [[ "$trimmed" =~ ^(sudo|git|curl|pacman|yay|docker|npm|cargo|pip|export|def|class|function|import|const|let|var)[[:space:]] ]]; then
                label="󰞷 ${clean:0:110}"
                echo -en "${id}\t${label}\0icon\x1futilities-terminal\n"

            # Standard text snippet (uses Papirus text editor icon instead of giant blank paper)
            else
                label="󰦨 ${clean:0:110}"
                echo -en "${id}\t${label}\0icon\x1faccessories-text-editor\n"
            fi
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
    0)  # ENTER — Paste (Supports Multi-Select Concatenation)
        item_count=$(echo "$clip_ids" | grep -c '^[0-9]')

        if [ "$item_count" -gt 1 ]; then
            # Multi-selection: join entries with double newlines
            merged_text=""
            while read -r id; do
                [ -z "$id" ] && continue
                entry_text=$(cliphist decode "$id" 2>/dev/null)
                if [ -n "$merged_text" ]; then
                    merged_text="${merged_text}"$'\n\n'"${entry_text}"
                else
                    merged_text="${entry_text}"
                fi
            done <<< "$clip_ids"

            echo -n "$merged_text" | wl-copy
            (sleep 0.12 && wtype -M ctrl -k v -m ctrl) &
            notify_pilot "Multi-Buffer Ready" "Merged ${item_count} items & pasted into active window."
        else
            first_id=$(echo "$clip_ids" | head -n 1)
            raw_head=$(cliphist decode "$first_id" 2>/dev/null | head -n 1)
            clean_head="${raw_head%$'\r'}"

            target_path=""
            if [[ "$clean_head" == file://* ]]; then
                raw_path="${clean_head#file://}"
                target_path=$(echo -e "${raw_path//%/\\x}")
            elif [[ "$clean_head" == /* ]] && [ -f "$clean_head" ]; then
                target_path="$clean_head"
            fi

            if [ -n "$target_path" ] && [ -f "$target_path" ]; then
                encoded_path="${target_path// /%20}"
                file_uri="file://${encoded_path}"
                echo -n "$file_uri" | wl-copy --type text/uri-list
            else
                mime_type=$(cliphist decode "$first_id" 2>/dev/null | file -b --mime-type -)
                if [[ "$mime_type" == image/* ]]; then
                    cliphist decode "$first_id" | wl-copy --type "$mime_type"
                else
                    cliphist decode "$first_id" | wl-copy
                fi
            fi

            (sleep 0.12 && wtype -M ctrl -k v -m ctrl) &
            notify_pilot "Buffer Updated" "Pasted into active window."
        fi
        ;;

    15) # Alt+P — Preview / Open Media (First item)
        first_id=$(echo "$clip_ids" | head -n 1)
        raw_head=$(cliphist decode "$first_id" 2>/dev/null | head -n 1)
        clean_head="${raw_head%$'\r'}"

        target_path=""
        if [[ "$clean_head" == file://* ]]; then
            raw_path="${clean_head#file://}"
            target_path=$(echo -e "${raw_path//%/\\x}")
        elif [[ "$clean_head" == /* ]] && [ -f "$clean_head" ]; then
            target_path="$clean_head"
        fi

        if [ -n "$target_path" ] && [ -f "$target_path" ]; then
            (xdg-open "$target_path") &
            notify_pilot "Visual Feed Active" "Opening ${target_path##*/}..."
        elif [[ "$clean_head" =~ ^https?:// ]]; then
            (xdg-open "$clean_head") &
            notify_pilot "Uplink Active" "Opening URL in browser..."
        else
            mime_type=$(cliphist decode "$first_id" 2>/dev/null | file -b --mime-type -)
            if [[ "$mime_type" == image/* ]]; then
                tmp_img="$CACHE_DIR/preview_${first_id}.png"
                cliphist decode "$first_id" > "$tmp_img"
                (xdg-open "$tmp_img") &
                notify_pilot "Visual Feed Active" "Opening image preview..."
            else
                notify_pilot "Text Preview" "${clean_head:0:300}"
            fi
        fi
        ;;

    10) # Alt+Delete — Delete Entry (Deep Purge)
        echo "$clip_ids" | while read -r id; do
            [ -z "$id" ] && continue
            decoded=$(cliphist decode "$id" 2>/dev/null)
            if [[ "$decoded" =~ ^file://(.+/.cache/pilot-hydra/ck_[^[:space:]]+) ]]; then
                rm -f "${BASH_REMATCH[1]}"
            fi
            cliphist list | awk -F'\t' -v id="$id" '$1 == id { print; exit }' | cliphist delete
        done
        notify_pilot "Entry Purged" "Clipboard item and thumbnail cache removed."
        ;;

    11) # Alt+Shift+Delete — Wipe All (Nuke)
        cliphist wipe
        rm -rf "$CACHE_DIR"/*
        rm -rf "$HOME/.cache/pilot-hydra"/*
        notify-send -u critical -a "Titanfall Systems" "DATABASE PURGED" "History and Hydra Cache erased."
        ;;

    12) # Alt+T — Safe Auto-Type
        first_id=$(echo "$clip_ids" | head -n 1)
        mime_type=$(cliphist decode "$first_id" 2>/dev/null | file -b --mime-type -)

        if [[ "$mime_type" == image/* ]] || [[ "$mime_type" == video/* ]]; then
            notify_pilot "Auto-Type Aborted" "Cannot simulate typing for media/image files."
            exit 0
        fi

        raw_text=$(cliphist decode "$first_id" 2>/dev/null)
        char_count=${#raw_text}

        if [ "$char_count" -gt 350 ]; then
            notify_pilot "Auto-Type Blocked" "Snippet too large (${char_count} chars). Use normal Paste (Enter) to prevent runaway typing."
            exit 0
        fi

        # Allow Rofi to vanish before typing into focused window
        sleep 0.15
        echo -n "$raw_text" | wtype -d 2 -
        notify_pilot "Buffer Typed" "Simulated typing (${char_count} chars)."
        ;;

    13) # Alt+O — Open URL(s) (Supports multiple URLs & text with embedded links)
        urls=()
        while read -r id; do
            [ -z "$id" ] && continue
            raw_text=$(cliphist decode "$id" 2>/dev/null)
            while IFS= read -r u; do
                [ -n "$u" ] && urls+=("$u")
            done < <(echo "$raw_text" | grep -Eo '(https?|ftp|file)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]')
        done <<< "$clip_ids"

        # Deduplicate URLs
        unique_urls=($(printf "%s\n" "${urls[@]}" | sort -u))

        if [ ${#unique_urls[@]} -eq 0 ]; then
            notify_pilot "No URL Found" "No valid web link detected in this clipboard entry."
        else
            open_count=0
            for u in "${unique_urls[@]}"; do
                xdg-open "$u" >/dev/null 2>&1 &
                open_count=$((open_count + 1))
                [ $open_count -ge 5 ] && break
            done
            notify_pilot "Uplink Active" "Opening ${open_count} URL(s) in browser..."
        fi
        ;;

    14) # Alt+E — Edit Selection (Annotate Screenshots with Swappy / Edit Text)
        first_id=$(echo "$clip_ids" | head -n 1)
        raw_head=$(cliphist decode "$first_id" 2>/dev/null | head -n 1)
        clean_head="${raw_head%$'\r'}"

        target_path=""
        if [[ "$clean_head" == file://* ]]; then
            raw_path="${clean_head#file://}"
            target_path=$(echo -e "${raw_path//%/\\x}")
        elif [[ "$clean_head" == /* ]] && [ -f "$clean_head" ]; then
            target_path="$clean_head"
        fi

        PREFERRED_EDITOR="${CLIPBOARD_EDITOR:-${VISUAL:-${EDITOR:-nvim}}}"
        if [ ! -x "$(which "$PREFERRED_EDITOR" 2>/dev/null)" ]; then
            which vim >/dev/null 2>&1 && PREFERRED_EDITOR="vim" || PREFERRED_EDITOR="nano"
        fi

        if [ -n "$target_path" ] && [ -f "$target_path" ]; then
            ext="${target_path##*.}"
            ext_lc=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

            case "$ext_lc" in
                png|jpg|jpeg|webp)
                    notify_pilot "Editing Media" "Opening image annotator for ${target_path##*/}..."
                    if which swappy >/dev/null 2>&1; then
                        swappy -f "$target_path" -o "$target_path"
                    else
                        xdg-open "$target_path" &
                    fi
                    ;;
                mp4|mkv|webm|avi|mov|flv|wmv|mp3|wav|ogg)
                    notify_pilot "Opening Media" "${target_path##*/}"
                    xdg-open "$target_path" &
                    ;;
                *)
                    notify_pilot "Editing File" "Opening ${target_path##*/} in ${PREFERRED_EDITOR}..."
                    if [ "$PREFERRED_EDITOR" == "code" ]; then
                        code "$target_path" &
                    else
                        kitty --class floating -e "$PREFERRED_EDITOR" "$target_path" &
                    fi
                    ;;
            esac
        else
            mime_type=$(cliphist decode "$first_id" 2>/dev/null | file -b --mime-type -)

            if [[ "$mime_type" == image/* ]]; then
                tmp_img="/tmp/cliphist-edit-$$.png"
                cliphist decode "$first_id" > "$tmp_img"

                if which swappy >/dev/null 2>&1; then
                    notify_pilot "Editing Screenshot" "Opening screenshot in Swappy..."
                    swappy -f "$tmp_img" -o "$tmp_img"
                    if [ -s "$tmp_img" ]; then
                        wl-copy --type image/png < "$tmp_img"
                        notify_pilot "Buffer Updated" "Annotated screenshot saved to clipboard."
                    fi
                else
                    xdg-open "$tmp_img" &
                fi
                rm -f "$tmp_img"
            else
                tmp_file="/tmp/cliphist-edit-$$.txt"
                > "$tmp_file"
                echo "$clip_ids" | while read -r id; do
                    [ -z "$id" ] && continue
                    cliphist decode "$id" >> "$tmp_file"
                    echo "" >> "$tmp_file"
                done

                notify_pilot "Editing Text Snippet" "Opening editor (${PREFERRED_EDITOR})..."

                if [ "$PREFERRED_EDITOR" == "code" ]; then
                    code -w "$tmp_file"
                else
                    kitty --class floating -e "$PREFERRED_EDITOR" "$tmp_file"
                fi

                if [ -s "$tmp_file" ]; then
                    cat "$tmp_file" | wl-copy
                    notify_pilot "Buffer Updated" "Edited text saved to clipboard."
                fi
                rm -f "$tmp_file"
            fi
        fi
        ;;
esac