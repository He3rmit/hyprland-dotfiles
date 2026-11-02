#!/usr/bin/env bash
# ~/.config/swaync/scripts/volume.sh
WPCTL="/usr/bin/wpctl"
NOTIFY="/usr/bin/notify-send"
STEP="5%"

case "$1" in
  up)    $WPCTL set-volume @DEFAULT_AUDIO_SINK@ "$STEP"+ ;;
  down)  $WPCTL set-volume @DEFAULT_AUDIO_SINK@ "$STEP"- ;;
  toggle) $WPCTL set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  *) echo "Usage: $0 {up|down|toggle}" >&2; exit 1 ;;
esac

OUT=$($WPCTL get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)

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

if [ "$MUTED" = "true" ]; then
    ICON="audio-volume-muted-symbolic"
    MSG="Volume muted"
    HINT_VAL=0
else
    ICON="audio-volume-high-symbolic"
    MSG="Volume: ${VOL_PERC}%"
    HINT_VAL=$VOL_PERC
fi

$NOTIFY -t 1000 -u low -i "$ICON" -h string:x-canonical-private-synchronous:sys-volume -h int:value:"$HINT_VAL" "Volume" "$MSG" 2>/dev/null &
