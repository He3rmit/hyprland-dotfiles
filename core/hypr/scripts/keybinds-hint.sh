#!/bin/bash
# ==============================================================================
# SCRIPT: keybinds-hint.sh
# PURPOSE: A dynamic, layout-aware Tactical Briefing for all HUD keybinds.
#          Uses XKB discovery to map physical keycodes to character labels.
# ==============================================================================

# Search paths
GLOBAL_BINDS="$HOME/.config/hypr/modules/keybinds.conf"
USER_BINDS="$HOME/.config/hypr/user-keybinds.conf"
KB_CONFIG="$HOME/.config/hypr/modules/keyboard.conf"

# The "Dynamic Translation" Table
declare -A KEYCODES

# --- STAGE 1: DYNAMIC INTELLIGENCE ENGINE ---
generate_keycode_map() {
    # 1. Extract Layout and Variant from Pilot's Configuration
    local layout=$(grep "kb_layout" "$KB_CONFIG" | awk -F '=' '{print $2}' | xargs)
    local variant=$(grep "kb_variant" "$KB_CONFIG" | awk -F '=' '{print $2}' | xargs)
    
    # Defaults
    layout=${layout:-us}
    variant=${variant:-""}

    # 2. Compile and Parse High-Fidelity Keymap
    local xkb_dump=$(xkbcli compile-keymap --layout "$layout" --variant "$variant" 2>/dev/null)
    if [[ -z "$xkb_dump" ]]; then return; fi

    # 3. Tactical Awk Parser: Double-Pass Mnemonic Mapping
    # This links physical codes to their actual character produces on your layout.
    while read -r entry; do
        local code=$(echo "$entry" | cut -d':' -f1)
        local symbol=$(echo "$entry" | cut -d':' -f2)
        # Ensure symbols like 'slash' or 'space' are capitalized or translated if needed
        KEYCODES["code:$code"]="${symbol^^}"
    done < <(echo "$xkb_dump" | awk '
        {
            # Pass 1: Capture Mnemonic -> Code (e.g. <AE01> = 10;)
            if (match($0, /<([A-Za-z0-9_]+)>[ \t]*=[ \t]*([0-9]+);/, arr)) {
                 code_map[arr[1]] = arr[2];
            }
            # Pass 2: Capture Mnemonic -> Symbol (e.g. key <AE01> { [ 1, )
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

# Static Regex Patterns
RE_CATEGORY='^#\ +CLUSTER\ [0-9]+:\ (.*)'
RE_BIND='^bind[el m]* *= *([^,]+), *([^,]+), *([^,]+)(, *(.*))?'
RE_HINT='#\ *(.*)'

# Execute Discovery
generate_keycode_map

# Parse function
parse_file() {
    local file="$1"
    local category="SYSTEM"
    
    if [[ ! -f "$file" ]]; then return; fi

    while IFS= read -r line; do
        # 1. Detect and Sanitize Categories
        if [[ "$line" =~ $RE_CATEGORY ]]; then
            category="${BASH_REMATCH[1]}"
            category=$(echo "$category" | sed -E 's/ *(\(|:|\[).*//; s/^THE //')
            category="${category^^}"
            continue
        fi

        # 2. Extract Binds
        if [[ "$line" =~ $RE_BIND ]]; then
            local mod="${BASH_REMATCH[1]}"
            local key="${BASH_REMATCH[2]}"
            local action="${BASH_REMATCH[3]}"
            local target="${BASH_REMATCH[5]}"
            local hint=""

            # Translation
            mod="${mod//\$mainMod/SUPER}"
            
            # 3. Dynamic Biological Translation
            if [[ ${KEYCODES[$key]+_} ]]; then
                key="${KEYCODES[$key]}"
            fi

            # 4. Extract Hint or Inferred Action
            if [[ "$line" =~ $RE_HINT ]]; then
                hint="${BASH_REMATCH[1]}"
            else
                hint=$(echo "$action $target" | sed 's/  */ /g')
            fi

            # Format for Rofi
            printf "[%-10s] %-18s 󰁔  %s\n" "$category" "$mod+$key" "$hint"
        fi
    done < "$file"
}

# Generate and Display
(
    parse_file "$GLOBAL_BINDS"
    parse_file "$USER_BINDS"
) | rofi -dmenu -i -p "Tactical Briefing" \
    -theme-str 'window {width: 1000px; height: 600px;} 
                listview {columns: 1; lines: 15; spacing: 8px; scrollbar: true;} 
                element {padding: 8px 12px;} 
                element-text {font: "ShureTechMono Nerd Font 14";}'
