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
            rfkill unblock bluetooth
        elif [[ "${SWAYNC_TOGGLE_STATE:-}" == "false" ]]; then
            rfkill block bluetooth
        elif [[ "$(rfkill list bluetooth)" == *"Soft blocked: yes"* ]]; then
            rfkill unblock bluetooth
        else
            rfkill block bluetooth
        fi
        ;;
    bt-status)
        bt_state=$(rfkill list bluetooth 2>/dev/null)
        [[ -n "$bt_state" && "$bt_state" != *"Soft blocked: yes"* ]] && echo true || echo false
        ;;
esac