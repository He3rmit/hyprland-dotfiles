#!/usr/bin/env bash

case "$1" in
    wifi)
        # Toggle Wifi
        nmcli radio wifi | grep -q "enabled" && nmcli radio wifi off || nmcli radio wifi on
        ;;
    bluetooth)
        # Toggle Bluetooth
        rfkill list bluetooth | grep -q "Soft blocked: yes" && rfkill unblock bluetooth || rfkill block bluetooth
        ;;
esac