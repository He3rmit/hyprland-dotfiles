#!/usr/bin/env bash
# ==============================================================================
# SwayNC Hardware-Adaptive Launcher
# Automatically detects and hooks the active backlight controller
# (e.g., Intel, AMD, ACPI) into SwayNC before starting the daemon.
# ==============================================================================

CONFIG_FILE="$HOME/.config/swaync/config.json"

if [ -f "$CONFIG_FILE" ]; then
    devs=(/sys/class/backlight/*)
    BACKLIGHT_DEV="${devs[0]##*/}"
    [[ "$BACKLIGHT_DEV" == "*" ]] && BACKLIGHT_DEV=""
    if [ -n "$BACKLIGHT_DEV" ]; then
        if grep -q '"device":' "$CONFIG_FILE"; then
            sed -i --follow-symlinks -E "s/\"device\": *\"[^\"]*\"/\"device\": \"$BACKLIGHT_DEV\"/" "$CONFIG_FILE"
        fi
    fi
fi

killall swaync 2>/dev/null
exec /usr/bin/swaync "$@"
