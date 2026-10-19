#!/usr/bin/env bash
# ~/.config/swaync/scripts/brightness.sh
devs=(/sys/class/backlight/*)
DEVICE="${devs[0]##*/}"
[[ "$DEVICE" == "*" ]] && DEVICE=""
if [ -z "$DEVICE" ]; then
    notify-send -u critical "Brightness" "No backlight device found"
    exit 1
fi
STEP="5%"                           
ID_FILE="/tmp/brightness_notif_id"  
BRCTL="/usr/bin/brightnessctl"
NOTIFY="/usr/bin/notify-send"

# Get hardware max directly from sysfs if available
if [[ -r "/sys/class/backlight/$DEVICE/max_brightness" ]]; then
    MAX=$(< "/sys/class/backlight/$DEVICE/max_brightness")
else
    MAX=$($BRCTL --class=backlight max 2>/dev/null)
fi

# Apply 95% cap workaround ONLY for AMD GPU devices (amdgpu_bl*) due to driver 65535 PWM wraparound bug
if [[ "$DEVICE" == amdgpu* ]]; then
    SAFE_MAX=$(( MAX * 95 / 100 ))
else
    SAFE_MAX=$MAX
fi

case "$1" in
  up)
    if [[ -r "/sys/class/backlight/$DEVICE/brightness" ]]; then
        CURRENT=$(< "/sys/class/backlight/$DEVICE/brightness")
    else
        CURRENT=$($BRCTL --class=backlight get 2>/dev/null)
    fi
    NEXT=$(( CURRENT + (MAX * 5 / 100) ))
    if [ "$NEXT" -ge "$SAFE_MAX" ]; then
      $BRCTL --class=backlight set "$SAFE_MAX" >/dev/null 2>&1
    else
      $BRCTL --class=backlight set +"$STEP" >/dev/null 2>&1
    fi
    ;;
  down) $BRCTL --class=backlight set "$STEP"- >/dev/null 2>&1 ;;
  *) echo "Usage: $0 {up|down}" >&2; exit 1 ;;
esac

# Get current state from sysfs
if [[ -r "/sys/class/backlight/$DEVICE/brightness" ]]; then
    BRIGHT=$(< "/sys/class/backlight/$DEVICE/brightness")
else
    BRIGHT=$($BRCTL --class=backlight get 2>/dev/null)
fi

if [ -z "$BRIGHT" ] || [ -z "$MAX" ] || [ "$MAX" -eq 0 ]; then
  $NOTIFY -u critical "Brightness" "Unable to read brightness"
  exit 1
fi

PERC=$(( BRIGHT * 100 / SAFE_MAX ))
if [ "$PERC" -gt 100 ]; then PERC=100; fi

OLD_ID=0
if [[ -s "$ID_FILE" ]]; then
    read -r val < "$ID_FILE" 2>/dev/null
    [[ "$val" =~ ^[0-9]+$ ]] && OLD_ID="$val"
fi

NEW_ID=$($NOTIFY -p -t 1200 -r "$OLD_ID" -u low -h int:value:"$PERC" -i display-brightness-symbolic "Brightness" "${PERC}%" 2>/dev/null)
[[ "$NEW_ID" =~ ^[0-9]+$ ]] && echo "$NEW_ID" > "$ID_FILE"