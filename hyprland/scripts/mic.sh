#!/usr/bin/env bash
# ~/.config/swaync/scripts/mic.sh
WPCTL=$(command -v wpctl)
NOTIFY=$(command -v notify-send)
ID_FILE="/tmp/mic_notif_id"
STEP="5%"

if [[ -z "$WPCTL" ]]; then
  [[ -n "$NOTIFY" ]] && $NOTIFY -u critical "Mic" "Error: 'wpctl' (Wireplumber) not found in PATH."
  echo "Error: wpctl not found." >&2
  exit 1
fi

# 1. TRANSMIT: Send the command to the audio source
case "$1" in
  up)    $WPCTL set-volume @DEFAULT_AUDIO_SOURCE@ "$STEP"+ ;;
  down)  $WPCTL set-volume @DEFAULT_AUDIO_SOURCE@ "$STEP"- ;;
  toggle) $WPCTL set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
  *) echo "Usage: $0 {up|down|toggle}" >&2; exit 1 ;;
esac

# 2. Query audio source state (immediate check with retry fallback for waking devices)
OUT=$($WPCTL get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
if [ -z "$OUT" ]; then
    for i in {1..5}; do
        sleep 0.1
        OUT=$($WPCTL get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
        if [ -n "$OUT" ]; then break; fi
    done
fi

# 3. VERIFY: If after 0.5s there is still no output, report a telemetry failure
if [ -z "$OUT" ]; then
  $NOTIFY -u critical "Mic" "Telemetry Lost: Microphone source not responding."
  exit 1
fi

# 4. PARSE: Extract volume and mute status
if [[ "$OUT" == *"[MUTED]"* || "$OUT" == *"MUTED"* ]]; then
  VOL_PERC=0
  MUTED=true
else
  MUTED=false
  num="${OUT#*Volume: }"
  num="${num%% *}"
  num="${num%%%*}"
  if [[ "$num" =~ ^([0-9]+)\.([0-9]{1,2}) ]]; then
    int_part="${BASH_REMATCH[1]}"
    dec_part="${BASH_REMATCH[2]}"
    [[ ${#dec_part} -eq 1 ]] && dec_part="${dec_part}0"
    VOL_PERC=$(( 10#$int_part * 100 + 10#$dec_part ))
  else
    VOL_PERC=$(( 10#${num:-0} ))
  fi
fi

# 5. NOTIFY: Update the SwayNC HUD
OLD_ID=0
if [[ -s "$ID_FILE" ]]; then
    read -r val < "$ID_FILE" 2>/dev/null
    [[ "$val" =~ ^[0-9]+$ ]] && OLD_ID="$val"
fi

if [ "$MUTED" = "true" ]; then
  ICON="microphone-sensitivity-muted-symbolic"
  MSG="Microphone muted"
  HINT_VAL=0
else
  ICON="microphone-sensitivity-high-symbolic"
  MSG="Microphone: ${VOL_PERC}%"
  HINT_VAL=$VOL_PERC
fi

# Sync physical micmute LED if brightnessctl is available
if command -v brightnessctl >/dev/null 2>&1; then
  if [ "$MUTED" = "true" ]; then
    brightnessctl --device="platform::micmute" set 1 >/dev/null 2>&1
  else
    brightnessctl --device="platform::micmute" set 0 >/dev/null 2>&1
  fi
fi

NEW_ID=$($NOTIFY -p -t 1200 -r "$OLD_ID" -u low -i "$ICON" -h int:value:"$HINT_VAL" "Microphone" "$MSG" 2>/dev/null)
[[ "$NEW_ID" =~ ^[0-9]+$ ]] && echo "$NEW_ID" > "$ID_FILE"
exit 0
