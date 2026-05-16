#!/bin/bash
# This script waits for network changes and triggers the portal login

# Give the system time to settle on boot
sleep 5

while true; do
    # Wait for any network connectivity change signal from NetworkManager
    nmcli monitor | grep -m 1 "connectivity"

    # Check if we are stuck at a portal
    if [ "$(nmcli connectivity)" = "portal" ]; then
        notify-send -u critical "Captive Portal Detected" "Network requires sign-in. Opening browser..."
        # Using neverssl as the trigger URL
        xdg-open "http://neverssl.com"
        # Sleep longer to avoid opening multiple tabs during the login process
        sleep 30
    fi
    sleep 2
done
