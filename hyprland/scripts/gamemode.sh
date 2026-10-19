#!/usr/bin/env bash

# ==============================================================================
# SCRIPT: gamemode.sh
# PURPOSE: Performance Optimizer Toggle for Hyprland
#          Temporarily strips compositor animations, blur, shadows, rounding,
#          and pauses hypridle to dedicate maximum GPU/CPU cycles to games.
# ==============================================================================

STATE_FILE="/tmp/hypr-gamemode.active"
PROFILE_FILE="/tmp/hypr-gamemode.profile"

notify_game() {
    local title="$1"
    local msg="$2"
    local urgency="${3:-low}"
    local icon="${4:-input-gaming}"
    notify-send -a "Game Mode" -u "$urgency" -i "$icon" "$title" "$msg" 2>/dev/null || true
}

is_active() {
    # Check live compositor state first to prevent desync across reloads
    local opt
    opt=$(hyprctl getoption animations:enabled 2>/dev/null)
    if [[ -n "$opt" ]]; then
        [[ "$opt" == *"false"* || "$opt" == *"int: 0"* ]]
        return $?
    fi
    [[ -f "$STATE_FILE" ]]
}

enable_gamemode() {
    # 1. Native Lua Parser (Hyprland v0.50+ / bilingual runtime)
    hyprctl eval "hl.config({
        animations = { enabled = false },
        decoration = {
            blur = { enabled = false },
            shadow = { enabled = false },
            rounding = 0,
            active_opacity = 1.0,
            inactive_opacity = 1.0,
        },
        general = {
            gaps_in = 0,
            gaps_out = 0,
            border_size = 1,
        }
    })" >/dev/null 2>&1 || \
    # 2. Legacy Parser Fallback
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:rounding 0;\
        keyword decoration:active_opacity 1.0;\
        keyword decoration:inactive_opacity 1.0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1" >/dev/null 2>&1

    # Pause hypridle so controller/gamepad sessions don't get screens timed out
    killall -STOP hypridle 2>/dev/null || true

    # Switch CPU power profile to performance (if available)
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl get > "$PROFILE_FILE" 2>/dev/null
        powerprofilesctl set performance 2>/dev/null || true
    fi

    touch "$STATE_FILE"
    pkill -RTMIN+8 waybar 2>/dev/null || true

    notify_game "Game Mode Engaged ⚡" "Maximum CPU performance, zero animations, and idle sleep disabled." "low" "input-gaming"
}

disable_gamemode() {
    # 1. Immediately re-enable animations via live eval for instant visual feedback
    hyprctl eval "hl.config({ animations = { enabled = true } })" >/dev/null 2>&1 || \
    hyprctl keyword animations:enabled 1 >/dev/null 2>&1

    # 2. Reload config to restore all user visual settings, blur, gaps & rounding
    hyprctl reload >/dev/null 2>&1

    # 3. Resume hypridle
    killall -CONT hypridle 2>/dev/null || true

    # 4. Restore previous power profile (with fallback to balanced)
    if command -v powerprofilesctl >/dev/null 2>&1; then
        local prev_profile="balanced"
        if [[ -f "$PROFILE_FILE" ]]; then
            local saved_profile
            saved_profile=$(cat "$PROFILE_FILE" 2>/dev/null)
            [[ -n "$saved_profile" ]] && prev_profile="$saved_profile"
            rm -f "$PROFILE_FILE"
        fi
        powerprofilesctl set "$prev_profile" 2>/dev/null || true
    fi

    rm -f "$STATE_FILE"
    pkill -RTMIN+8 waybar 2>/dev/null || true

    notify_game "Game Mode Disengaged ✨" "Desktop visuals, power profile, and idle timers restored." "low" "preferences-desktop-theme"
}

# --- CLI DISPATCH ---
case "$1" in
    --status)
        if is_active; then
            echo '{"text":"󰊖 GAME","class":"active","tooltip":"Game Mode: ACTIVE (Performance Boosted)\nClick to restore desktop visuals"}'
        else
            echo '{"text":"","class":"inactive","tooltip":"Game Mode: Inactive"}'
        fi
        exit 0
        ;;
    --enable|-e)
        enable_gamemode
        ;;
    --disable|-d)
        disable_gamemode
        ;;
    --toggle|-t|"")
        if is_active; then
            disable_gamemode
        else
            enable_gamemode
        fi
        ;;
    *)
        echo "Usage: $0 [--toggle|--enable|--disable|--status]"
        exit 1
        ;;
esac
