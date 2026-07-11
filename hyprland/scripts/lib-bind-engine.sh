#!/bin/bash
# ==============================================================================
# LIBRARY: lib-bind-engine.sh (LUA MIGRATION EDITION)
# PURPOSE: Parses Lua keybind configuration files to preserve Rofi HUD groupings.
# ==============================================================================

# Search paths (Defaults)
KB_CONFIG="$HOME/.config/hypr/modules/keyboard.lua"

# The Dynamic Translation Table
declare -A KEYCODES

# --- ENGINE: KEYCODE DISCOVERY ---
generate_keycode_map() {
    local layout=$(grep "kb_layout" "$KB_CONFIG" 2>/dev/null | awk -F '=' '{print $2}' | xargs)
    local variant=$(grep "kb_variant" "$KB_CONFIG" 2>/dev/null | awk -F '=' '{print $2}' | xargs)

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
            if (match($0, /key[ \t]+<([A-Za-z0-9_]+)>[ \t]*\{[ \t]*\[[ \t]*([^,\t\]]+)/, arr)) {
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
declare -a BIND_KEYS
declare -A BIND_VALUES

TAB=$'\t'

add_or_update_bind() {
    local key_combo="$1"
    local category="$2"
    local hint="$3"

    if [[ -z "${BIND_VALUES[$key_combo]}" ]]; then
        BIND_KEYS+=("$key_combo")
    fi
    BIND_VALUES["$key_combo"]="${category}${TAB}${hint}"
}

remove_bind() {
    local key_combo="$1"
    if [[ -n "${BIND_VALUES[$key_combo]}" ]]; then
        unset BIND_VALUES["$key_combo"]
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
    local RE_CATEGORY='^-- *CLUSTER [0-9]+: *(.*)'
    local RE_BIND='^hl\.bind\(([^,]+), *(.*)\)'
    local RE_HINT='-- *(.*)'

    if [[ ! -f "$file" ]]; then return; fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ $RE_CATEGORY ]]; then
            category="${BASH_REMATCH[1]}"
            category=$(echo "$category" | sed -E 's/ *(\(|:|\[).*//; s/^THE //')
            category="${category^^}"
            continue
        fi

        if [[ "$line" =~ $RE_BIND ]]; then
            local key_combo="${BASH_REMATCH[1]}"
            local action="${BASH_REMATCH[2]}"
            
            # Clean up key_combo (e.g., mainMod .. " + Q" -> SUPER + Q)
            key_combo=$(echo "$key_combo" | sed 's/mainMod/"SUPER"/g; s/ \.\. / /g; s/"//g')
            key_combo=$(echo "$key_combo" | sed 's/  */ /g; s/^+ //; s/ \+ /+/g')
            
            local hint=""
            if [[ "$line" =~ $RE_HINT ]]; then
                hint="${BASH_REMATCH[1]}"
            else
                # Extract inner action 
                hint=$(echo "$action" | sed -E 's/hl\.dsp\.[a-z_]+\((.*)\)/\1/; s/"//g; s/\)$//')
                # Truncate long commands
                hint=$(echo "$hint" | cut -c 1-60)
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

generate_keycode_map
