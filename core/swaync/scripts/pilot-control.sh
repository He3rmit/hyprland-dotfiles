#!/usr/bin/env bash

case "$1" in
    wifi)
        # Toggle Wifi without subshell grep
        if [[ "$(nmcli radio wifi)" == *"enabled"* ]]; then
            nmcli radio wifi off
        else
            nmcli radio wifi on
        fi
        ;;
    bluetooth)
        # Toggle Bluetooth without subshell grep
        if [[ "$(rfkill list bluetooth)" == *"Soft blocked: yes"* ]]; then
            rfkill unblock bluetooth
        else
            rfkill block bluetooth
        fi
        ;;
esac