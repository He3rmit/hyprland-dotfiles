#!/usr/bin/env bash
# ~/.config/swaync/scripts/power-profile-cycle.sh
# Cycles through power-profiles-daemon modes: balanced -> power-saver -> performance

CTL=$(command -v powerprofilesctl)
NOTIFY=$(command -v notify-send)

if [ -z "$CTL" ]; then
    [ -n "$NOTIFY" ] && $NOTIFY -u critical "Power" "power-profiles-daemon not found."
    exit 1
fi

CURRENT=$($CTL get)

case "$CURRENT" in
    balanced)
        NEXT="power-saver"
        ICON="battery-low"
        MSG="Power Saver Mode"
        ;;
    power-saver)
        NEXT="performance"
        ICON="performance-level"
        MSG="Performance Mode"
        ;;
    performance|*)
        NEXT="balanced"
        ICON="battery-good"
        MSG="Balanced Mode"
        ;;
esac

$CTL set "$NEXT"

if [ -n "$NOTIFY" ]; then
    $NOTIFY -u low -t 2000 -i "$ICON" "Power Profile" "$MSG"
fi
