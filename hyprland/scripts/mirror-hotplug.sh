#!/usr/bin/env bash

# ==============================================================================
# PROJECT / MIRROR HOTPLUG — Windows 11 Style Display Projection Switcher
# Options:
#   1. 💻 PC screen only     (Internal screen on, external off)
#   2. 🪞 Duplicate          (Clone/mirror screen for presentation)
#   3. ↔️ Extend             (Dual monitor workspace)
#   4. 📺 Second screen only (External screen on, internal off)
# ==============================================================================

STATE_FILE="/tmp/hypr-display-state"
ROFI_THEME="$HOME/.config/rofi/themes/selector.rasi"

notify_display() {
    local title="$1"
    local msg="$2"
    local urgency="${3:-normal}"
    notify-send -a "Display" -u "$urgency" -t 2500 \
        -h "string:x-canonical-private-synchronous:display-project" \
        "$title" "$msg" 2>/dev/null || true
}

# --- 1. HARDWARE DETECTION ---
MONITORS_JSON=$(hyprctl monitors all -j 2>/dev/null || echo "[]")

# Find built-in laptop panel (eDP, LVDS, DSI)
LAPTOP=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name | test("^(eDP|LVDS|DSI)")) | .name' | head -1)

# Find first external display (HDMI, DP, DisplayPort, etc.)
EXTERNAL=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name | test("^(eDP|LVDS|DSI)") | not) | .name' | head -1)

# Preserve configured scaling
LAPTOP_SCALE=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$LAPTOP\") | .scale // 1" | head -1)
[[ -z "$LAPTOP_SCALE" || "$LAPTOP_SCALE" == "null" ]] && LAPTOP_SCALE="1"

EXT_SCALE=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$EXTERNAL\") | .scale // 1" | head -1)
[[ -z "$EXT_SCALE" || "$EXT_SCALE" == "null" ]] && EXT_SCALE="1"

if [[ -z "$LAPTOP" ]]; then
    notify_display "Display Error" "No built-in laptop screen detected." "critical"
    exit 1
fi

# --- 2. IPC DISPATCHERS ---
set_monitor() {
    local output="$1"
    local mode="${2:-preferred}"
    local pos="${3:-auto}"
    local scale="${4:-1}"
    local mirror="$5"

    local lua_cmd
    if [[ -n "$mirror" ]]; then
        lua_cmd="hl.monitor({ output = \"$output\", mode = \"$mode\", position = \"$pos\", scale = $scale, mirror = \"$mirror\", disabled = false })"
    else
        # Explicit mirror = "" unhooks any previous mirror relationship in Hyprland
        lua_cmd="hl.monitor({ output = \"$output\", mode = \"$mode\", position = \"$pos\", scale = $scale, mirror = \"\", disabled = false })"
    fi

    local res
    res=$(hyprctl eval "$lua_cmd" 2>&1)
    if [[ "$res" != *"ok"* ]]; then
        # Legacy parser fallback
        if [[ -n "$mirror" ]]; then
            hyprctl keyword monitor "$output, $mode, $pos, $scale, mirror, $mirror" 2>/dev/null || true
        else
            hyprctl keyword monitor "$output, $mode, $pos, $scale" 2>/dev/null || true
        fi
    fi
}

disable_monitor() {
    local output="$1"
    local lua_cmd="hl.monitor({ output = \"$output\", disabled = true })"
    local res
    res=$(hyprctl eval "$lua_cmd" 2>&1)
    if [[ "$res" != *"ok"* ]]; then
        hyprctl keyword monitor "$output, disable" 2>/dev/null || true
    fi
}

# --- 3. ENVIRONMENT HEALING (Wallpaper & Waybar) ---
refresh_environment() {
    # Re-initialize wallpaper across all active displays
    local wp_script="$HOME/.config/hypr/scripts/wallpaper-selector.sh"
    if [[ -x "$wp_script" ]]; then
        "$wp_script" --init >/dev/null 2>&1 &
    fi

    # Refresh Waybar output anchors
    pkill -SIGUSR2 waybar 2>/dev/null || true
}

# --- 4. DISPLAY PROJECTION ACTIONS ---
action_pc_only() {
    notify_display "Project" "💻 PC screen only"
    set_monitor "$LAPTOP" "preferred" "auto" "$LAPTOP_SCALE"
    sleep 0.15
    if [[ -n "$EXTERNAL" ]]; then
        disable_monitor "$EXTERNAL"
    fi
    echo "0" > "$STATE_FILE"
    refresh_environment
}

action_duplicate() {
    if [[ -z "$EXTERNAL" ]]; then
        notify_display "Project" "No external display detected. Plug HDMI/DP in first."
        action_pc_only
        return
    fi
    notify_display "Project" "🪞 Duplicate (Presentation)"
    set_monitor "$LAPTOP" "preferred" "auto" "$LAPTOP_SCALE"
    set_monitor "$EXTERNAL" "preferred" "auto" "$LAPTOP_SCALE" "$LAPTOP"
    sleep 0.2
    echo "1" > "$STATE_FILE"
    refresh_environment
}

action_extend() {
    if [[ -z "$EXTERNAL" ]]; then
        notify_display "Project" "No external display detected. Plug HDMI/DP in first."
        action_pc_only
        return
    fi
    notify_display "Project" "↔️ Extend"
    set_monitor "$LAPTOP" "preferred" "auto" "$LAPTOP_SCALE"
    set_monitor "$EXTERNAL" "preferred" "auto-right" "$EXT_SCALE"
    sleep 0.2
    echo "2" > "$STATE_FILE"
    refresh_environment
}

action_second_only() {
    if [[ -z "$EXTERNAL" ]]; then
        notify_display "Project" "No external display detected. Plug HDMI/DP in first."
        action_pc_only
        return
    fi
    notify_display "Project" "📺 Second screen only"
    # Turn on external FIRST so compositor never enters a 0-output void
    set_monitor "$EXTERNAL" "preferred" "auto" "$EXT_SCALE"
    sleep 0.35

    # Verify external output handshake before shutting off laptop screen
    if hyprctl monitors -j 2>/dev/null | jq -e ".[] | select(.name == \"$EXTERNAL\")" >/dev/null 2>&1; then
        disable_monitor "$LAPTOP"
    else
        notify_display "Display Warning" "External screen handshake pending. Keeping laptop screen on." "critical"
    fi
    echo "3" > "$STATE_FILE"
    refresh_environment
}

# --- 5. WINDOWS 11 STYLE FLYOUT MENU ---
show_menu() {
    local opt1="💻  PC screen only"
    local opt2="🪞  Duplicate"
    local opt3="↔️   Extend"
    local opt4="📺  Second screen only"

    local menu_items="$opt1\n$opt2\n$opt3\n$opt4"
    local choice

    if [[ -f "$ROFI_THEME" ]]; then
        choice=$(echo -e "$menu_items" | rofi -dmenu -i -p "󰍺 Project" -theme "$ROFI_THEME")
    else
        choice=$(echo -e "$menu_items" | rofi -dmenu -i -p "󰍺 Project")
    fi

    [[ -z "$choice" ]] && exit 0

    case "$choice" in
        *"PC screen only"*)    action_pc_only ;;
        *"Duplicate"*)         action_duplicate ;;
        *"Extend"*)            action_extend ;;
        *"Second screen only"*) action_second_only ;;
    esac
}

# --- 6. ROUTER ---
case "$1" in
    --cycle)
        if [[ -z "$EXTERNAL" ]]; then
            notify_display "Project" "No external display detected. Laptop display active."
            action_pc_only
            exit 0
        fi

        CURRENT_STATE=0
        [[ -f "$STATE_FILE" ]] && CURRENT_STATE=$(cat "$STATE_FILE")
        NEXT_STATE=$(( (CURRENT_STATE + 1) % 4 ))

        case "$NEXT_STATE" in
            0) action_pc_only ;;
            1) action_duplicate ;;
            2) action_extend ;;
            3) action_second_only ;;
        esac
        ;;
    --pc-only|0)
        action_pc_only
        ;;
    --duplicate|1)
        action_duplicate
        ;;
    --extend|2)
        action_extend
        ;;
    --second-only|3)
        action_second_only
        ;;
    --menu|*)
        show_menu
        ;;
esac