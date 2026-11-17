#!/usr/bin/env bash

case "$1" in
    wifi)
        if [[ "${SWAYNC_TOGGLE_STATE:-}" == "true" ]]; then
            nmcli radio wifi on
        elif [[ "${SWAYNC_TOGGLE_STATE:-}" == "false" ]]; then
            nmcli radio wifi off
        elif [[ "$(nmcli radio wifi)" == *"enabled"* ]]; then
            nmcli radio wifi off
        else
            nmcli radio wifi on
        fi
        ;;
    wifi-status)
        [[ "$(nmcli radio wifi 2>/dev/null)" == *"enabled"* ]] && echo true || echo false
        ;;
    bluetooth)
        if [[ "${SWAYNC_TOGGLE_STATE:-}" == "true" ]]; then
            rfkill unblock bluetooth 2>/dev/null || true
            sleep 0.2
            bluetoothctl power on >/dev/null 2>&1 || true
        elif [[ "${SWAYNC_TOGGLE_STATE:-}" == "false" ]]; then
            bluetoothctl power off >/dev/null 2>&1 || true
            rfkill block bluetooth 2>/dev/null || true
        elif [[ "$(rfkill list bluetooth)" == *"Soft blocked: yes"* ]] || ! (bluetoothctl show 2>/dev/null | grep -q "Powered: yes"); then
            rfkill unblock bluetooth 2>/dev/null || true
            sleep 0.2
            bluetoothctl power on >/dev/null 2>&1 || true
        else
            bluetoothctl power off >/dev/null 2>&1 || true
            rfkill block bluetooth 2>/dev/null || true
        fi
        ;;
    bt-status)
        if command -v bluetoothctl >/dev/null 2>&1; then
            bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo true || echo false
        else
            bt_state=$(rfkill list bluetooth 2>/dev/null)
            [[ -n "$bt_state" && "$bt_state" != *"Soft blocked: yes"* ]] && echo true || echo false
        fi
        ;;
    sunset)
        if [[ "${SWAYNC_TOGGLE_STATE:-}" == "true" ]]; then
            (
                nohup bash -c '
                    STATE_FILE="/tmp/hypr-sunset.active"
                    pkill -x hyprsunset 2>/dev/null
                    while pgrep -u "$UID" -x hyprsunset >/dev/null; do sleep 0.05; done
                    hyprctl dispatch "hl.dsp.exec_cmd(\"hyprsunset -t 4500\")" >/dev/null 2>&1
                    touch "$STATE_FILE"
                    notify-send -a "Night Light" -u low -i "weather-clear-night" -h string:x-canonical-private-synchronous:sys-sunset "Night Light" "Engaged (Warm 4500K) 🌙" 2>/dev/null
                ' </dev/null >/dev/null 2>&1 &
            )
        elif [[ "${SWAYNC_TOGGLE_STATE:-}" == "false" ]]; then
            (
                nohup bash -c '
                    STATE_FILE="/tmp/hypr-sunset.active"
                    pkill -x hyprsunset 2>/dev/null
                    while pgrep -u "$UID" -x hyprsunset >/dev/null; do sleep 0.05; done
                    hyprctl dispatch "hl.dsp.exec_cmd(\"hyprsunset\")" >/dev/null 2>&1
                    rm -f "$STATE_FILE"
                    notify-send -a "Night Light" -u low -i "weather-clear" -h string:x-canonical-private-synchronous:sys-sunset "Night Light" "Disabled (Schedule Restored) ☀️" 2>/dev/null
                ' </dev/null >/dev/null 2>&1 &
            )
        else
            (
                nohup bash -c '
                    STATE_FILE="/tmp/hypr-sunset.active"
                    pid=$(pgrep -u "$UID" -x hyprsunset 2>/dev/null | head -n1)
                    if [[ -f "$STATE_FILE" ]] || { [[ -n "$pid" ]] && tr "\0" " " < "/proc/$pid/cmdline" | grep -q -- "-t"; }; then
                        pkill -x hyprsunset 2>/dev/null
                        while pgrep -u "$UID" -x hyprsunset >/dev/null; do sleep 0.05; done
                        hyprctl dispatch "hl.dsp.exec_cmd(\"hyprsunset\")" >/dev/null 2>&1
                        rm -f "$STATE_FILE"
                        notify-send -a "Night Light" -u low -i "weather-clear" -h string:x-canonical-private-synchronous:sys-sunset "Night Light" "Disabled (Schedule Restored) ☀️" 2>/dev/null
                    else
                        pkill -x hyprsunset 2>/dev/null
                        while pgrep -u "$UID" -x hyprsunset >/dev/null; do sleep 0.05; done
                        hyprctl dispatch "hl.dsp.exec_cmd(\"hyprsunset -t 4500\")" >/dev/null 2>&1
                        touch "$STATE_FILE"
                        notify-send -a "Night Light" -u low -i "weather-clear-night" -h string:x-canonical-private-synchronous:sys-sunset "Night Light" "Engaged (Warm 4500K) 🌙" 2>/dev/null
                    fi
                ' </dev/null >/dev/null 2>&1 &
            )
        fi
        ;;
    sunset-status)
        STATE_FILE="/tmp/hypr-sunset.active"
        pid=$(pgrep -u "$UID" -x hyprsunset 2>/dev/null | head -n1)
        if [[ -f "$STATE_FILE" ]] || { [[ -n "$pid" ]] && tr "\0" " " < "/proc/$pid/cmdline" | grep -q -- "-t"; }; then
            echo true
        else
            echo false
        fi
        ;;
    gamemode)
        if [[ "${SWAYNC_TOGGLE_STATE:-}" == "true" ]]; then
            (nohup ~/.config/hypr/scripts/gamemode.sh --enable </dev/null >/dev/null 2>&1 &)
        elif [[ "${SWAYNC_TOGGLE_STATE:-}" == "false" ]]; then
            (nohup ~/.config/hypr/scripts/gamemode.sh --disable </dev/null >/dev/null 2>&1 &)
        else
            (nohup ~/.config/hypr/scripts/gamemode.sh --toggle </dev/null >/dev/null 2>&1 &)
        fi
        ;;
    gamemode-status)
        ~/.config/hypr/scripts/gamemode.sh --check
        ;;
esac