#!/bin/bash
# ==============================================================================
# LIBRARY: lib-bind-engine.sh
# PURPOSE: The "Neural Core" of the Pilot HUD. Encapsulates keybind discovery,
#          keycode translation, and config parsing for reuse across the HUD.
# ==============================================================================

# Search paths (Defaults)
KB_CONFIG="$HOME/.config/hypr/modules/keyboard.conf"

# The Dynamic Translation Table
declare -A KEYCODES

# --- ENGINE: KEYCODE DISCOVERY ---
# Builds a real-time map of physical keycodes to active layout symbols.
generate_keycode_map() {
    local layout=$(grep "kb_layout" "$KB_CONFIG" | awk -F '=' '{print $2}' | xargs)
    local variant=$(grep "kb_variant" "$KB_CONFIG" | awk -F '=' '{print $2}' | xargs)
    
    layout=${layout:-us}
    variant=${variant:-""}

    local xkb_dump=$(xkbcli compile-keymap --layout "$layout" --variant "$variant" 2>/dev/null)
    if [[ -z "$xkb_dump" ]]; then return; fi

    while read -r entry; do
        local code=$(echo "$entry" | cut -d':' -f1)
        local symbol=$(echo "$entry" | cut -d':' -f2)
        KEYCODES["code:$code"]="${symbol^^}"
    done < <(echo "$xkb_dump" | awk '
        {
            if (match($0, /<([A-Za-z0-9_]+)>[ \t]*=[ \t]*([0-9]+);/, arr)) {
                 code_map[arr[1]] = arr[2];
            }
            if (match($0, /key[ \t]+<([A-Za-z0-9_]+)>[ \t]*\{[ \t]*\[[ \t]*([^, \t\]]+)/, arr)) {
                if (arr[1] in code_map) {
                    symbol = arr[2];
                    gsub(/"/, "", symbol);
                    print code_map[arr[1]] ":" symbol;
                }
            }
        }
    ')
}

# --- ENGINE: DATA EXTRACTION ---
# Global State for Tracking Keybinds (Preserves order, handles overrides/unbounds)
declare -a BIND_KEYS
declare -A BIND_VALUES

TAB=$'\t'

add_or_update_bind() {
    local key_combo="$1"
    local category="$2"
    local hint="$3"
    
    # If not already present in BIND_VALUES, record it in the ordered keys list
    if [[ -z "${BIND_VALUES[$key_combo]}" ]]; then
        BIND_KEYS+=("$key_combo")
    fi
    BIND_VALUES["$key_combo"]="${category}${TAB}${hint}"
}

remove_bind() {
    local key_combo="$1"
    if [[ -n "${BIND_VALUES[$key_combo]}" ]]; then
        unset BIND_VALUES["$key_combo"]
        # Rebuild BIND_KEYS to maintain correct order and filter out the unbound key
        local temp_keys=()
        for k in "${BIND_KEYS[@]}"; do
            if [[ "$k" != "$key_combo" ]]; then
                temp_keys+=("$k")
            fi
        done
        BIND_KEYS=("${temp_keys[@]}")
    fi
}

parse_bind_file() {
    local file="$1"
    local category="SYSTEM"
    local RE_CATEGORY='^#\ +CLUSTER\ [0-9]+:\ (.*)'
    local RE_BIND='^bind[el m]* *= *([^,]+), *([^,]+), *([^,]+)(, *(.*))?'
    local RE_UNBIND='^unbind *= *([^,]+), *([^,]+)'
    local RE_HINT='#\ *(.*)'
    
    if [[ ! -f "$file" ]]; then return; fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # 1. Category Sanitization
        if [[ "$line" =~ $RE_CATEGORY ]]; then
            category="${BASH_REMATCH[1]}"
            category=$(echo "$category" | sed -E 's/ *(\(|:|\[).*//; s/^THE //')
            category="${category^^}"
            continue
        fi

        # 2. Unbind Extraction (Overrides)
        if [[ "$line" =~ $RE_UNBIND ]]; then
            local mod="${BASH_REMATCH[1]}"
            local key="${BASH_REMATCH[2]}"
            
            mod="${mod//\$mainMod/SUPER}"
            mod=$(echo "$mod" | xargs)
            key=$(echo "$key" | xargs)
            
            if [[ ${KEYCODES[$key]+_} ]]; then
                key="${KEYCODES[$key]}"
            fi
            
            local key_combo=""
            if [[ -n "$mod" ]]; then
                key_combo="${mod}+${key}"
            else
                key_combo="${key}"
            fi
            key_combo=$(echo "$key_combo" | sed 's/  */ /g')
            
            remove_bind "$key_combo"
            continue
        fi

        # 3. Bind Extraction
        if [[ "$line" =~ $RE_BIND ]]; then
            local mod="${BASH_REMATCH[1]}"
            local key="${BASH_REMATCH[2]}"
            local action="${BASH_REMATCH[3]}"
            local target="${BASH_REMATCH[5]}"
            local hint=""

            # Internal mod translation
            mod="${mod//\$mainMod/SUPER}"
            mod=$(echo "$mod" | xargs)
            key=$(echo "$key" | xargs)
            
            # Keycode translation (if map exists)
            if [[ ${KEYCODES[$key]+_} ]]; then
                key="${KEYCODES[$key]}"
            fi
            
            local key_combo=""
            if [[ -n "$mod" ]]; then
                key_combo="${mod}+${key}"
            else
                key_combo="${key}"
            fi
            key_combo=$(echo "$key_combo" | sed 's/  */ /g')

            # 4. Hint Extraction
            if [[ "$line" =~ $RE_HINT ]]; then
                hint="${BASH_REMATCH[1]}"
            else
                # Fallback: Cleaned raw action
                hint=$(echo "$action $target" | sed 's/  */ /g')
            fi

            add_or_update_bind "$key_combo" "$category" "$hint"
        fi
    done < "$file"
}

print_bind_list() {
    for k in "${BIND_KEYS[@]}"; do
        if [[ -n "${BIND_VALUES[$k]}" ]]; then
            local val="${BIND_VALUES[$k]}"
            local category="${val%%$TAB*}"
            local hint="${val#*$TAB}"
            printf "%s\t%s\t%s\n" "$category" "$k" "$hint"
        fi
    done
}

# Auto-initialize the map if sourced
generate_keycode_map

