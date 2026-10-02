#!/bin/bash
# -----------------------------------------------------
# Titanfall Pilot Screenshot & Annotation Engine
# Prioritizes Satty, falls back to Swappy, or directly copies
# -----------------------------------------------------

# 1. Close the Pilot HUD so it doesn't block the shot
swaync-client -cp > /dev/null 2>&1
sleep 0.2

# 2. Capture area with slurp (safely abort if cancelled with Esc)
GEOM=$(slurp)
[ -z "$GEOM" ] && exit 0

# 3. Take screenshot and open annotator
if which satty >/dev/null 2>&1; then
    grim -g "$GEOM" - | satty --filename - --early-exit
elif which swappy >/dev/null 2>&1; then
    grim -g "$GEOM" - | swappy -f -
else
    grim -g "$GEOM" - | wl-copy --type image/png
    notify-send -u normal -a "Titanfall Systems" -i "camera-photo" "Screenshot Captured" "Saved directly to clipboard."
fi