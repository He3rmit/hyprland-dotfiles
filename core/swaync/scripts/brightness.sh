#!/usr/bin/env bash
# ~/.config/swaync/scripts/brightness.sh
DEVICE=$(ls /sys/class/backlight/ 2>/dev/null | head -n 1)
if [ -z "$DEVICE" ]; then
    notify-send -u critical "Brightness" "No backlight device found"
    exit 1
fi
STEP="5%"                           
ID_FILE="/tmp/brightness_notif_id"  
BRCTL="/usr/bin/brightnessctl"
NOTIFY="/usr/bin/notify-send"

# Get hardware max
MAX=$($BRCTL --class=backlight max | head -n 1 2>/dev/null)

# Apply 95% cap workaround ONLY for AMD GPU devices (amdgpu_bl*) due to driver 65535 PWM wraparound bug
if [[ "$DEVICE" == amdgpu* ]]; then
    SAFE_MAX=$(( MAX * 95 / 100 ))
else
    SAFE_MAX=$MAX
fi

case "$1" in
  up)
    CURRENT=$($BRCTL --class=backlight get | head -n 1 2>/dev/null)
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

sleep 0.08

# Get current state from the backlight class (universal)
BRIGHT=$($BRCTL --class=backlight get | head -n 1 2>/dev/null)
if [ -z "$BRIGHT" ] || [ -z "$MAX" ] || [ "$MAX" -eq 0 ]; then
  $NOTIFY -u critical "Brightness" "Unable to read brightness"
  exit 1
fi

PERC=$(( BRIGHT * 100 / SAFE_MAX ))
if [ "$PERC" -gt 100 ]; then PERC=100; fi

OLD_ID=0
if [ -f "$ID_FILE" ]; then OLD_ID=$(cat "$ID_FILE" 2>/dev/null || echo 0); fi

NEW_ID=$($NOTIFY -p -t 1200 -r "$OLD_ID" -u low -h int:value:"$PERC" -i display-brightness-symbolic "Brightness" "${PERC}%")
if [ -z "$NEW_ID" ]; then NEW_ID="$OLD_ID"; fi
echo "$NEW_ID" > "$ID_FILE"