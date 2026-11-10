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

# 0. ENGINE RESTART PROTOCOL
reload_waybar() {
    pkill -x waybar 2>/dev/null
    while pgrep -u "$UID" -x waybar >/dev/null; do sleep 0.05; done
    waybar -c "$CONFIG_FILE" -s "$STYLE_FILE" & disown
}

# 1. Ask what to change
MODE=$(echo -e "Change Layout (Modules)\nChange Style (CSS)" | rofi -dmenu -i -p "󰸉 Waybar" -theme "$ROFI_THEME")

if [[ -z "$MODE" ]]; then
    exit 0
fi

if [[ "$MODE" == "Change Layout (Modules)" ]]; then
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
            notify-send "Waybar Engine" "ERROR: Source layout not found!"
            exit 1
        fi
        
        # If preserving the same Axis, sync the position memory!
        if [[ -f "$CONFIG_FILE" ]]; then
            CURRENT_POS=$(grep -Eo '"position": *"[a-zA-Z]+"' "$CONFIG_FILE" | cut -d'"' -f4 | head -n 1)
            CURRENT_NAME=$(readlink -f "$CONFIG_FILE")
            
        fi
        
        # Copy template to active config instead of symlinking to protect the repo source
        # BREAK THE LINK: Ensure the active config is a real file, not a symlink to the repo
        rm -f "$CONFIG_FILE"
        cp "$target_file" "$CONFIG_FILE"
        chmod 644 "$CONFIG_FILE"

        fi

        notify-send -t 2000 "Waybar Engine" "Layout updated: $selected_name"
        

        # ENGINE RESTART
        reload_waybar
    fi

elif [[ "$MODE" == "Change Style (CSS)" ]]; then
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
        notify-send -t 2000 "Waybar Engine" "Style updated: $selected_name" &
        
        # ENGINE RESTART
        reload_waybar
    fi
fi

# ==============================================================================
# SWAYNC DYNAMIC ALIGNMENT
# ==============================================================================
sync_swaync_position() {
    local wbb_config="$HOME/.config/waybar/config.jsonc"
    local swaync_config="$HOME/.config/swaync/config.json"
    
    if [[ -f "$wbb_config" && -f "$swaync_config" ]]; then
        # BREAK THE LINK: Ensure the active swaync config is a real file, not a symlink to the repo
        if [[ -L "$swaync_config" ]]; then
            local real_path=$(readlink -f "$swaync_config")
            rm -f "$swaync_config"
            cp "$real_path" "$swaync_config"
            chmod 644 "$swaync_config"
        fi

        local wb_pos="top"
        if [[ -r "$wbb_config" ]]; then
            local wb_content
            wb_content=$(< "$wbb_config")
            if [[ "$wb_content" =~ \"position\":[[:space:]]*\"([a-zA-Z]+)\" ]]; then
                wb_pos="${BASH_REMATCH[1]}"
            fi
        fi
        
        # Determine the module block containing the notification/tray icon
        local has_left=$(grep -E '"modules-left":.*("custom/notification"|"tray")' "$wbb_config")
        local has_center=$(grep -E '"modules-center":.*("custom/notification"|"tray")' "$wbb_config")
        local has_right=$(grep -E '"modules-right":.*("custom/notification"|"tray")' "$wbb_config")
        
        local target_x="right"
        local target_y="top"
        
        if [[ "$wb_pos" == "left" || "$wb_pos" == "right" ]]; then
            # Sidebar Mode (Vertical Flow)
            # Panel X-Axis locked to Waybar position
            target_x="$wb_pos"
            
            # Panel Y-Axis defined by internal structural modules (Left=Top, Center=Center, Right=Bottom)
            if [[ -n "$has_left" ]]; then target_y="top"
            elif [[ -n "$has_right" ]]; then target_y="bottom"
            elif [[ -n "$has_center" ]]; then target_y="center"
            fi
        else
            # Topbar/Bottombar Mode (Horizontal Flow)
            # Panel Y-Axis locked to Waybar position
            target_y="top"
            [[ "$wb_pos" == "bottom" ]] && target_y="bottom"
            
            # Panel X-Axis defined by internal structural modules (Left=Left, Center=Center, Right=Right)
            if [[ -n "$has_left" ]]; then target_x="left"
            elif [[ -n "$has_right" ]]; then target_x="right"
            elif [[ -n "$has_center" ]]; then target_x="center"
            fi
        fi
        
        sed -i --follow-symlinks -E 's/"positionX": *"[a-zA-Z]+"/"positionX": "'"$target_x"'"/' "$swaync_config"
        sed -i --follow-symlinks -E 's/"positionY": *"[a-zA-Z]+"/"positionY": "'"$target_y"'"/' "$swaync_config"
        
        swaync-client -R >/dev/null 2>&1
        swaync-client -rs >/dev/null 2>&1
    fi
}

sync_swaync_position
