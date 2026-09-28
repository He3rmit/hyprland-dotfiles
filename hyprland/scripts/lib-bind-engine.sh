#!/bin/bash
# ==============================================================================
# LIBRARY: lib-bind-engine.sh (DYNAMIC LUA BRIEFING ENGINE)
# PURPOSE: Parses Lua keybind configuration files to preserve Rofi HUD groupings,
#          translates AST dispatchers to clean pseudocode, and dynamically maps
#          hardware keycodes via active XKB layout.
# ==============================================================================

# Search paths (Defaults)
KB_CONFIG="$HOME/.config/hypr/modules/keyboard.lua"

# The Dynamic Translation Table
declare -A KEYCODES

# --- ENGINE: KEYCODE DISCOVERY ---
generate_keycode_map() {
    local layout=$(grep "kb_layout" "$KB_CONFIG" 2>/dev/null | awk -F '=' '{print $2}' | tr -d '", ' | xargs)
    local variant=$(grep "kb_variant" "$KB_CONFIG" 2>/dev/null | awk -F '=' '{print $2}' | tr -d '", ' | xargs)

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

# --- ENGINE: KEY SANITIZER ---
clean_key() {
    local k="$1"

    # Normalize Lua string concatenation & mainMod
    k=$(echo "$k" | sed 's/mainMod/"SUPER"/g; s/ \.\. / /g; s/"//g; s/  */ /g; s/ \+ /+/g')

    # Mouse & Touchpad Special mappings
    k="${k//mouse:272/LMB (Drag)}"
    k="${k//mouse:273/RMB (Resize)}"
    k="${k//mouse_down/Scroll Down}"
    k="${k//mouse_up/Scroll Up}"
    k="${k//code:202/Fn + F9 (Touchpad)}"

    # Dynamic XKB Keycode mapping (e.g., code:61 -> /, code:10 -> 1)
    if [[ "$k" =~ code:([0-9]+) ]]; then
        local c="code:${BASH_REMATCH[1]}"
        if [[ -n "${KEYCODES[$c]}" ]]; then
            local sym="${KEYCODES[$c]}"
            [[ "$sym" == "SLASH" ]] && sym="/"
            k="${k//$c/$sym}"
        fi
    fi

    # Format XF86 keys into readable titles (e.g. XF86MonBrightnessUp -> Mon Brightness Up)
    k=$(echo "$k" | sed -E 's/XF86([A-Z])/ \1/g; s/([a-z])([A-Z])/\1 \2/g; s/  */ /g; s/^ //')
    k=$(echo "$k" | sed 's/+/ + /g; s/  */ /g')
    echo "$k"
}

# --- ENGINE: PSEUDOCODE TRANSLATOR ---
clean_pseudocode() {
    local action="$1"
    local comment="$2"

    # Priority 1: User inline comment (excluding keycode reminders like "code:39 = S")
    if [[ -n "$comment" && ! "$comment" =~ ^code:[0-9]+ ]]; then
        echo "$comment" | xargs
        return
    fi

    # Strip trailing Lua table options (e.g. , { locked = true, repeating = true })
    action=$(echo "$action" | sed -E 's/, *\{.*\} *$//')

    # Window management actions
    if [[ "$action" =~ hl\.dsp\.window\.([a-zA-Z0-9_]+) ]]; then
        local method="${BASH_REMATCH[1]}"
        if [[ "$action" =~ workspace\ *=\ *\"?([^\"\}]+) ]]; then
            echo "move window -> ${BASH_REMATCH[1]}"
            return
        fi
        case "$method" in
            drag)       echo "window: drag" ;;
            resize)     echo "window: resize" ;;
            close)      echo "window: close" ;;
            float)      echo "window: toggle float" ;;
            fullscreen) echo "window: toggle fullscreen" ;;
            pseudo)     echo "window: pseudo tile" ;;
            *)          echo "window: $method" ;;
        esac
        return
    fi

    # Navigation / Focus
    if [[ "$action" =~ hl\.dsp\.focus ]]; then
        if [[ "$action" =~ direction\ *=\ *\"?([a-zA-Z0-9_]+) ]]; then
            echo "focus: ${BASH_REMATCH[1]}"
            return
        elif [[ "$action" =~ workspace\ *=\ *\"?([^\"\}]+) ]]; then
            echo "workspace: ${BASH_REMATCH[1]}"
            return
        fi
    fi

    # Special Workspaces / Scratchpads
    if [[ "$action" =~ hl\.dsp\.workspace\.toggle_special\(\"?([^\"]+)\"?\) ]]; then
        echo "scratchpad: ${BASH_REMATCH[1]}"
        return
    fi

    # Layout actions
    if [[ "$action" =~ hl\.dsp\.layout\(\"?([^\"]+)\"?\) ]]; then
        echo "layout: ${BASH_REMATCH[1]}"
        return
    fi

    # Executed commands & scripts: strip paths and wrappers
    if [[ "$action" =~ hl\.dsp\.exec_cmd\((.*)\) ]]; then
        local cmd="${BASH_REMATCH[1]}"
        cmd=$(echo "$cmd" | sed -E "s/^[ \"'\''\(]+//; s/[ \"'\''\)]+$//")
        if [[ "$cmd" =~ /([^/]+)$ ]]; then
            echo "exec: ${BASH_REMATCH[1]}"
        else
            echo "exec: $cmd"
        fi
        return
    fi

    # Fallback: Strip generic Lua wrapper and quotes
    local fallback=$(echo "$action" | sed -E 's/hl\.dsp\.[a-z_.]+\((.*)\)/\1/; s/\{[^}]*\}//g; s/\"//g' | xargs)
    echo "${fallback:-$action}"
}

# --- ENGINE: DATA STORAGE ---
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

    # Contextual defaults based on configuration tier
    [[ "$file" == *"host.lua"* ]] && category="HARDWARE"
    [[ "$file" == *"user-keybinds.lua"* ]] && category="USER WORKFLOW"

    local RE_CATEGORY='^-- *CLUSTER [0-9]+: *(.*)'
    local RE_BIND='^hl\.bind\(([^,]+), *(.*)\)'
    local RE_UNBIND='^hl\.unbind\(([^)]+)\)'
    local RE_HINT='-- *(.*)'

    if [[ ! -f "$file" ]]; then return; fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ $RE_CATEGORY ]]; then
            category="${BASH_REMATCH[1]}"
            category=$(echo "$category" | sed -E 's/ *(\(|:|\[).*//; s/^THE //')
            category="${category^^}"
            continue
        fi

        if [[ "$line" =~ "Mouse Interaction" ]]; then
            category="MOUSE & WINDOW"
        fi

        if [[ "$line" =~ $RE_UNBIND ]]; then
            local ukey=$(clean_key "${BASH_REMATCH[1]}")
            remove_bind "$ukey"
            continue
        fi

        if [[ "$line" =~ $RE_BIND ]]; then
            local raw_key="${BASH_REMATCH[1]}"
            local action="${BASH_REMATCH[2]}"
            local key_combo=$(clean_key "$raw_key")

            local comment=""
            if [[ "$line" =~ $RE_HINT ]]; then
                comment="${BASH_REMATCH[1]}"
            fi

            local hint=$(clean_pseudocode "$action" "$comment")
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
