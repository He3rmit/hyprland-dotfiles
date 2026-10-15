#!/bin/bash

# --- VARIABLES ---
LAPTOP_BAT=""
PERIPH_BAT=""
TOOLTIP_MSG=""
MAIN_CLASS="discharging"
HAS_CRITICAL=false
IS_CHARGING=false

SEPARATOR=$'\n'
[[ "$1" == "--horizontal" ]] && SEPARATOR=" "

# Pure bash parser for upower device properties (zero subshells)
parse_upower() {
    local info="$1"
    DEV_MODEL=""
    DEV_PERCENT=""
    DEV_STATE=""
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        if [[ "$line" == model:* ]]; then
            DEV_MODEL="${line#model:}"
            DEV_MODEL="${DEV_MODEL#"${DEV_MODEL%%[![:space:]]*}"}"
            DEV_MODEL="${DEV_MODEL%"${DEV_MODEL##*[![:space:]]}"}"
            DEV_MODEL="${DEV_MODEL//&/&amp;}"
        elif [[ "$line" == percentage:* ]]; then
            DEV_PERCENT="${line#percentage:}"
            DEV_PERCENT="${DEV_PERCENT//[ %[:space:]]/}"
            DEV_PERCENT="${DEV_PERCENT%.*}"
        elif [[ "$line" == state:* ]]; then
            DEV_STATE="${line#state:}"
            DEV_STATE="${DEV_STATE#"${DEV_STATE%%[![:space:]]*}"}"
            DEV_STATE="${DEV_STATE%"${DEV_STATE##*[![:space:]]}"}"
        fi
    done <<< "$info"
}

# --- 1. SINGLE UPOWER ENUMERATION ---
mapfile -t ALL_DEVICES < <(timeout 1s upower -e 2>/dev/null)

BAT_DEVICE=""
for dev in "${ALL_DEVICES[@]}"; do
    if [[ "$dev" == *"BAT"* ]]; then
        BAT_DEVICE="$dev"
        break
    fi
done

if [ -n "$BAT_DEVICE" ]; then
    BAT_INFO=$(timeout 1s upower -i "$BAT_DEVICE" 2>/dev/null)
    parse_upower "$BAT_INFO"
    BAT_LEVEL="$DEV_PERCENT"
    BAT_STATE="$DEV_STATE"

    ICON="BAT"
    [[ "$BAT_STATE" == "charging" ]] && ICON="⚡"
    LAPTOP_BAT="${ICON}${SEPARATOR}${BAT_LEVEL}%"

    if [[ "$BAT_STATE" == "charging" ]]; then IS_CHARGING=true; fi
    # Only flag critical if BAT_LEVEL is actually a number
    if [[ -n "$BAT_LEVEL" ]] && [[ "$BAT_LEVEL" -le 20 ]]; then HAS_CRITICAL=true; fi

    TOOLTIP_MSG+="Laptop Battery: ${BAT_LEVEL}% (${BAT_STATE})"'\n'
fi

# --- 2. PERIPHERALS ONLY ---
for DEV_PATH in "${ALL_DEVICES[@]}"; do
    # Skip display devices, AC power, and laptop battery
    if [[ "$DEV_PATH" == *"line_power"* ]] || [[ "$DEV_PATH" == *"DisplayDevice"* ]] || [[ "$DEV_PATH" == *"BAT"* ]]; then
        continue
    fi

    INFO=$(timeout 1s upower -i "$DEV_PATH" 2>/dev/null)
    parse_upower "$INFO"
    MODEL="$DEV_MODEL"
    PERCENT="$DEV_PERCENT"
    STATE="$DEV_STATE"

    if [ -z "$PERCENT" ]; then continue; fi
    if [ -z "$STATE" ]; then STATE="active"; fi

    # Phantom 0% fix for peripherals
    if [[ "$PERCENT" == "0" ]]; then continue; fi

    TOOLTIP_MSG+="${MODEL}: ${PERCENT}% (${STATE})"'\n'

    # Smart Icon Logic
    if [[ "$DEV_PATH" == *"mouse"* ]]; then DEV_ICON="󰍽"
    elif [[ "$DEV_PATH" == *"keyboard"* ]]; then DEV_ICON="󰌌"
    elif [[ "$DEV_PATH" == *"headset"* ]] || [[ "$DEV_PATH" == *"audio"* ]]; then DEV_ICON="󰋋"
    else DEV_ICON=""; fi

    [[ "$STATE" == "charging" ]] && DEV_ICON="⚡$DEV_ICON"

    if [ -n "$PERIPH_BAT" ]; then
        PERIPH_BAT+="${SEPARATOR}"
    fi
    PERIPH_BAT+="${DEV_ICON}${SEPARATOR}${PERCENT}%"
done

# --- 3. DETERMINE CLASS ---
[[ "$IS_CHARGING" == true ]] && MAIN_CLASS="charging"
[[ "$HAS_CRITICAL" == true ]] && MAIN_CLASS="critical"

if [ -n "$PERIPH_BAT" ] && [ -n "$LAPTOP_BAT" ]; then
    FINAL_TEXT="${PERIPH_BAT}${SEPARATOR}${LAPTOP_BAT}"
elif [ -n "$PERIPH_BAT" ]; then
    FINAL_TEXT="$PERIPH_BAT"
elif [ -n "$LAPTOP_BAT" ]; then
    FINAL_TEXT="$LAPTOP_BAT"
else
    FINAL_TEXT=""
fi

CLEAN_TOOLTIP="${TOOLTIP_MSG//$'\n'/\\n}"
CLEAN_TEXT="${FINAL_TEXT//$'\n'/\\n}"
printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$CLEAN_TEXT" "$CLEAN_TOOLTIP" "$MAIN_CLASS"

# --- 4. SAFETY CHECKS (Prevent Spam) ---
if [ -n "$BAT_DEVICE" ] && [ -n "$BAT_LEVEL" ]; then
    if [[ "$BAT_LEVEL" -le 20 ]] && [[ "$BAT_STATE" != "charging" ]]; then
        if [ ! -f /tmp/reactor_instability_sent ]; then
            notify-send -u critical "REACTOR INSTABILITY" "Battery Level: ${BAT_LEVEL}% - Seek Power Source"
            touch /tmp/reactor_instability_sent
        fi
    else
        rm -f /tmp/reactor_instability_sent
    fi
fi