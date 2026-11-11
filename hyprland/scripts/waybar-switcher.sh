#!/usr/bin/env bash
# ==============================================================================
# WAYBAR HUD SWITCHER
# ==============================================================================

WAYBAR_DIR="$HOME/.config/waybar"
CONFIG_FILE="$WAYBAR_DIR/config.jsonc"
STYLE_FILE="$WAYBAR_DIR/style.css"

# Look inside the dotfiles source to avoid Stow symlink issues
LAYOUTS_DIR="$HOME/.config/waybar/layouts"
STYLES_DIR="$HOME/.config/waybar/styles"
ROFI_THEME="$HOME/.config/rofi/themes/selector.rasi"

# Ensure origin directories exist just in case
mkdir -p "$LAYOUTS_DIR" "$STYLES_DIR"

# Helper to adjust sidebar margin for right-hand side
apply_sidebar_position() {
    local target_pos="${1,,}"
    local cfg="$2"
    local current_pos
    current_pos=$(grep -Eo '"position": *"[a-zA-Z]+"' "$cfg" | cut -d'"' -f4 | head -n 1)
    current_pos="${current_pos,,}"
    [[ -z "$current_pos" ]] && current_pos="left"

    if [[ "$current_pos" != "$target_pos" ]]; then
        sed -i -E "s/\"position\": *\"[a-zA-Z]+\"/\"position\": \"$target_pos\"/" "$cfg"
        local current_margin
        current_margin=$(grep -Eo '"margin": *"[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+"' "$cfg" | head -n 1)
        if [[ -n "$current_margin" ]]; then
            local m_vals
            m_vals=$(echo "$current_margin" | sed -E 's/.*"margin": *"([0-9]+ +[0-9]+ +[0-9]+ +[0-9]+)".*/\1/')
            read -r top right bottom left <<< "$m_vals"
            local swapped_margin="\"margin\": \"$top $left $bottom $right\""
            sed -i -E "s/\"margin\": *\"[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+\"/$swapped_margin/" "$cfg"
        fi
    fi
}

# ==============================================================================
# SWAYNC DYNAMIC ALIGNMENT
# ==============================================================================
sync_swaync_position() {
    local wbb_config="$HOME/.config/waybar/config.jsonc"
    local swaync_config="$HOME/.config/swaync/config.json"

    if [[ -f "$wbb_config" && -f "$swaync_config" ]]; then
        # BREAK THE LINK: Ensure the active swaync config is a real file, not a symlink to the repo
        if [[ -L "$swaync_config" ]]; then
            local real_path
            real_path=$(readlink -f "$swaync_config")
            rm -f "$swaync_config"
            cp "$real_path" "$swaync_config"
            chmod 644 "$swaync_config"
        fi

        local wb_pos="top"
        local anchor_block="none"
        if [[ -r "$wbb_config" ]]; then
            local parsed
            parsed=$(python3 - "$wbb_config" <<'EOF'
import json, re, sys
try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        raw = f.read()
    # Strip JSONC // and /* */ comments outside strings, then trailing commas
    clean = re.sub(r'("(?:\\.|[^"\\])*")|//[^\n]*|/\*.*?\*/', lambda m: m.group(1) or "", raw, flags=re.S)
    clean = re.sub(r",(\s*[}\]])", r"\1", clean)
    data = json.loads(clean)
except Exception:
    print("top none")
    sys.exit(0)

pos = str(data.get("position", "top")).lower()
if pos not in ("left", "right", "top", "bottom"):
    pos = "top"

def contains_module(mods, target):
    if not isinstance(mods, list):
        return False
    if target in mods:
        return True
    return any(
        isinstance(m, str) and m.startswith("group/") and isinstance(data.get(m), dict)
        and target in data[m].get("modules", [])
        for m in mods
    )

anchor = "none"
for target in ("custom/notification", "tray"):
    for side in ("left", "center", "right"):
        if contains_module(data.get(f"modules-{side}", []), target):
            anchor = side
            break
    if anchor != "none":
        break

print(f"{pos} {anchor}")
EOF
)
            read -r wb_pos anchor_block <<< "$parsed"
        fi

        local target_x="right"
        local target_y="top"

        if [[ "$wb_pos" == "left" || "$wb_pos" == "right" ]]; then
            # Sidebar Mode (Vertical Flow): X locked to Waybar edge, Y follows notification block
            target_x="$wb_pos"
            case "$anchor_block" in
                left)   target_y="top" ;;
                right)  target_y="bottom" ;;
                center) target_y="center" ;;
            esac
        else
            # Topbar/Bottombar Mode (Horizontal Flow): Y locked to Waybar edge, X follows notification block
            target_y="top"
            [[ "$wb_pos" == "bottom" ]] && target_y="bottom"
            case "$anchor_block" in
                left)   target_x="left" ;;
                right)  target_x="right" ;;
                center) target_x="center" ;;
            esac
        fi

        sed -i --follow-symlinks -E 's/"positionX": *"[a-zA-Z]+"/"positionX": "'"$target_x"'"/' "$swaync_config"
        sed -i --follow-symlinks -E 's/"positionY": *"[a-zA-Z]+"/"positionY": "'"$target_y"'"/' "$swaync_config"

    fi

    sync_swaync_theme

    if pgrep -u "$UID" -x swaync >/dev/null 2>&1; then
        swaync-client -R >/dev/null 2>&1 || true
        swaync-client -rs >/dev/null 2>&1 || true
    fi
}

sync_swaync_theme() {
    local swaync_dir="$HOME/.config/swaync"
    local swaync_theme="$swaync_dir/theme.css"
    local themes_dir="$swaync_dir/themes"
    local header=""
    local theme_name="1-Titan-Glass"

    if [[ ! -d "$themes_dir" ]] && [[ -L "$swaync_dir/style.css" ]]; then
        themes_dir="$(dirname "$(readlink -f "$swaync_dir/style.css")")/themes"
    fi

    [[ -f "$STYLE_FILE" ]] && header="$(head -n 5 "$STYLE_FILE" 2>/dev/null)"
    case "$header" in
        *"FLAT DYNAMIC"*)        theme_name="2-Flat-Material" ;;
        *"NEON BORDER DYNAMIC"*) theme_name="3-Neon-Border" ;;
        *"CYBERPUNK GLITCH"*)    theme_name="4-Cyberpunk-Glitch" ;;
        *"GLASS PILL"*)          theme_name="5-Glass-Pill" ;;
        *"TITANFALL PILOT HUD"*) theme_name="1-Titan-Glass" ;;
    esac

    local src_theme="$themes_dir/${theme_name}.css"
    if [[ -f "$src_theme" ]]; then
        # BREAK THE LINK: Keep live theme.css independent of repo core/swaync/theme.css
        if [[ -L "$swaync_theme" ]] || [[ ! -f "$swaync_theme" ]] || ! cmp -s "$src_theme" "$swaync_theme"; then
            rm -f "$swaync_theme"
            cp "$src_theme" "$swaync_theme"
            chmod 644 "$swaync_theme"
        fi
    fi
}

if [[ "${1:-}" == "--sync-swaync" ]]; then
    sync_swaync_position
    exit 0
fi

# 0. ENGINE RESTART PROTOCOL
reload_waybar() {
    pkill -x waybar 2>/dev/null
    while pgrep -u "$UID" -x waybar >/dev/null; do sleep 0.05; done
    sync_swaync_position
    waybar -c "$CONFIG_FILE" -s "$STYLE_FILE" & disown
}

# 1. Ask what to change
MODE=$(echo -e "Change Layout\nChange Style" | rofi -dmenu -i -p "󰸉 Waybar" -theme "$ROFI_THEME")

if [[ -z "$MODE" ]]; then
    exit 0
fi

if [[ "$MODE" == "Change Layout" ]]; then
    # 2a. List layouts (pure bash globbing, zero child processes)
    cd "$LAYOUTS_DIR" || exit 1
    options_arr=()
    for f in *.jsonc; do
        [[ -e "$f" ]] || continue
        options_arr+=("${f%.jsonc}")
    done
    options=$(printf "%s\n" "${options_arr[@]}")
    
    if [[ -z "$options" ]]; then
        notify-send "Waybar Switcher" "No layouts found!" &
        exit 1
    fi
    
    selected_name=$(echo -e "$options" | rofi -dmenu -i -p "󰸉 Layout" -theme "$ROFI_THEME")
    
    if [[ -n "$selected_name" ]]; then
        target_file="$LAYOUTS_DIR/${selected_name}.jsonc"
        
        if [[ ! -f "$target_file" ]]; then
            notify-send "Waybar Engine" "ERROR: Source layout not found!" &
            exit 1
        fi

        # Context prompt: If user selected a Sidebar, immediately ask for screen edge
        SIDE=""
        if [[ "$selected_name" == *"Sidebar"* ]]; then
            SIDE=$(echo -e "Left\nRight" | rofi -dmenu -i -p "󰸉 Screen Edge" -theme "$ROFI_THEME")
            [[ -z "$SIDE" ]] && exit 0
        fi
        
        # Copy template to active config instead of symlinking to protect the repo source
        # BREAK THE LINK: Ensure the active config is a real file, not a symlink to the repo
        rm -f "$CONFIG_FILE"
        cp "$target_file" "$CONFIG_FILE"
        chmod 644 "$CONFIG_FILE"

        if [[ -n "$SIDE" ]]; then
            apply_sidebar_position "$SIDE" "$CONFIG_FILE"
        fi

        # ENGINE RESTART (syncs SwayNC orientation before confirmation toast fires)
        reload_waybar
        notify-send -t 2000 "Waybar Engine" "Layout updated: $selected_name" &
    fi

elif [[ "$MODE" == "Change Style" ]]; then
    # 2b. List styles (pure bash globbing, zero child processes)
    cd "$STYLES_DIR" || exit 1
    options_arr=()
    for f in *.css; do
        [[ -e "$f" ]] || continue
        options_arr+=("${f%.css}")
    done
    options=$(printf "%s\n" "${options_arr[@]}")
    
    if [[ -z "$options" ]]; then
        notify-send "Waybar Switcher" "No styles found!" &
        exit 1
    fi
    
    selected_name=$(echo -e "$options" | rofi -dmenu -i -p "󰸉 Style" -theme "$ROFI_THEME")
    
    if [[ -n "$selected_name" ]]; then
        target_file="$STYLES_DIR/${selected_name}.css"
        
        if [[ ! -f "$target_file" ]]; then
            notify-send "Waybar Engine" "ERROR: Source style not found!" &
            exit 1
        fi
        
        # Copy template to active style instead of symlinking
        # BREAK THE LINK: Ensure the active style is a real file, not a symlink to the repo
        rm -f "$STYLE_FILE"
        cp "$target_file" "$STYLE_FILE"
        chmod 644 "$STYLE_FILE"
        # ENGINE RESTART
        reload_waybar
        notify-send -t 2000 "Waybar Engine" "Style updated: $selected_name" &
    fi
fi
