#!/bin/bash
# -----------------------------------------------------
# Waybar World Clock & Timezone Selector (Rofi Runner Theme)
# -----------------------------------------------------

THEME="$HOME/.config/rofi/themes/runner.rasi"
[ ! -f "$THEME" ] && THEME="$HOME/.config/rofi/config.rasi"

CITIES=(
    "Asia/Manila|Manila, Philippines (PHT)"
    "Asia/Tokyo|Tokyo, Japan (JST)"
    "UTC|UTC (Universal Time)"
    "Europe/London|London, UK (BST/GMT)"
    "Europe/Paris|Paris, France (CEST)"
    "Europe/Berlin|Berlin, Germany (CEST)"
    "America/New_York|New York, USA (EDT/EST)"
    "America/Chicago|Chicago, USA (CDT/CST)"
    "America/Los_Angeles|Los Angeles, USA (PDT/PST)"
    "Asia/Singapore|Singapore (SGT)"
    "Asia/Hong_Kong|Hong Kong (HKT)"
    "Asia/Shanghai|Shanghai / Beijing, China (CST)"
    "Asia/Kolkata|New Delhi / Mumbai, India (IST)"
    "Asia/Dubai|Dubai, UAE (GST)"
    "Australia/Sydney|Sydney, Australia (AEST)"
)

MENU_ITEMS=""

for item in "${CITIES[@]}"; do
    tz="${item%%|*}"
    name="${item#*|}"
    time_str=$(TZ="$tz" date +"%H:%M  (%Z / UTC%z)")
    MENU_ITEMS+="${name}\t->  ${time_str}\n"
done

SELECTION=$(echo -e -n "$MENU_ITEMS" | rofi -dmenu -i -p "󰥔 World Clock" -theme "$THEME")

if [ -n "$SELECTION" ]; then
    CITY_NAME=$(echo "$SELECTION" | awk -F '\t->  ' '{print $1}')
    TIME_DETAILS=$(echo "$SELECTION" | awk -F '\t->  ' '{print $2}')
    notify-send -u normal -a "World Clock" -i "clock" "󰥔 ${CITY_NAME}" "Current Time: ${TIME_DETAILS}"
fi
