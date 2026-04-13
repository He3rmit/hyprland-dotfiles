#!/usr/bin/env bash
# ==============================================================================
# TITAN PILOT HUD: GUI CONTROL PROTOCOL
# ==============================================================================

ROFI_THEME="$HOME/.config/rofi/themes/runner.rasi"
PILOT_CONTROL="$HOME/.local/bin/pilot-control"

# 1. Main Menu Options
options="[ SDDM ] Engage Cinematic HUD\n[ SDDM ] Disengage HUD (Restore Defaults)\n[ STATUS ] Check HUD Integrity"

# 2. Launch Rofi
choice=$(echo -e "$options" | rofi -dmenu -i -p "󰸉 Pilot Control" -theme "$ROFI_THEME")

if [[ -z "$choice" ]]; then
    exit 0
fi

# 3. Handle Choices
case "$choice" in
    *"Engage Cinematic HUD"*)
        # We use kitty to execute so the user can see/enter sudo password
        kitty -e bash -c "$PILOT_CONTROL sddm --engage; echo 'Press any key to exit...'; read -n 1"
        ;;
    *"Disengage HUD"*)
        kitty -e bash -c "$PILOT_CONTROL sddm --disengage; echo 'Press any key to exit...'; read -n 1"
        ;;
    *"Check HUD Integrity"*)
        status=$($PILOT_CONTROL sddm --status)
        notify-send -t 5000 "Pilot Control" "$status"
        ;;
esac
