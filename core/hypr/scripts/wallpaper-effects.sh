#!/usr/bin/env bash

# Fetch exactly what is playing
CURRENT_WALLPAPER_FILE="$HOME/.config/wallpapers/.current_wallpaper"
if [[ ! -f "$CURRENT_WALLPAPER_FILE" ]]; then
    exit 1
fi

selected_path=$(cat "$CURRENT_WALLPAPER_FILE")

# If it's a video, ignore (or show notification)
if [[ "$selected_path" =~ \.(mp4|webm|mkv)$ ]]; then
    notify-send -u normal "Wallpaper Effects" "Effects are not supported on video wallpapers."
    exit 0
fi

CACHE_DIR="$HOME/.cache/wallpaper-thumbnails"
mkdir -p "$CACHE_DIR"

# If it is an image, prompt the Effects Menu
EFFECTS="Original\n[ PILOT VISION ]\nBloom (Cinematic)\nVanguard Tactical (Orange/Green)\nCyber HUD (Cyan/Magenta)\nNight Vision\n-\n[ DIGITAL MODES ]\nGlitch (Purge)\nCRT Retro\nNoir (High Contrast)\nPixelate\nVignette"
selected_effect=$(echo -e "$EFFECTS" | rofi -dmenu -i -p "󰸉 Vision Mode" -theme "$HOME/.config/rofi/themes/runner.rasi")

if [[ -z "$selected_effect" || "$selected_effect" == "-" || "$selected_effect" == "[ "* ]]; then
    exit 0
fi

if [[ "$selected_effect" == "Original" ]]; then
    ~/.config/hypr/scripts/wallpaper-selector.sh --set "$selected_path"
    exit 0
fi

notify-send -t 3000 -h string:x-canonical-private-synchronous:sys-notify -u normal "Wall-E" "Syncing Vision Mode: $selected_effect..."

TIMESTAMP=$(date +%s)
EFFECT_FILE="$CACHE_DIR/current_wallpaper_effect_${TIMESTAMP}.jpg"
GRID_TILE="$CACHE_DIR/grid_tile.png"

# Clean up old effects to prevent cache bloat
rm -f "$CACHE_DIR"/current_wallpaper_effect_*.jpg 2>/dev/null

# Helper for Grid Generation
generate_grid() {
    local color="$1"
    magick -size 80x80 xc:none -draw "stroke $color stroke-width 1 line 0,0 80,0 line 0,0 0,80" "$GRID_TILE"
}

case "$selected_effect" in
    "Bloom (Cinematic)")
        # Cinematic Bloom V2: Catching more highlights with a wider, softer lens glow
        magick "$selected_path" \( +clone -level 20,100% -blur 0x25 -modulate 100,120,100 \) -compose Screen -composite "$EFFECT_FILE"
        ;;
    "Vanguard Tactical (Orange/Green)")
        # Titanfall Colors: #1A2F1A (Dark Green) & #E55A00 (Militia Orange)
        # Adds a subtle overlay grid for the 'HUD' feel
        generate_grid "rgba(229,90,0,0.3)"
        magick "$selected_path" -modulate 100,120,100 +level-colors "#1A2F1A","#E55A00" \
            \( -clone 0 -tile "$GRID_TILE" -draw "color 0,0 reset" \) -compose Overlay -composite "$EFFECT_FILE"
        ;;
    "Cyber HUD (Cyan/Magenta)")
        # Cyberpunk Colors: #1B032A (Purple) & #00E0FF (Cyan)
        generate_grid "rgba(0,224,255,0.4)"
        magick "$selected_path" -modulate 110,140,100 +level-colors "#1B032A","#00E0FF" \
            \( -clone 0 -tile "$GRID_TILE" -draw "color 0,0 reset" \) -compose Screen -composite "$EFFECT_FILE"
        ;;
    "Night Vision")
        magick "$selected_path" -colorspace gray +level-colors "#061A06","#00FF33" \
            -modulate 100,150,100 -sharpen 0x2 "$EFFECT_FILE"
        ;;
    "Glitch (Purge)")
        # Chromatic aberration
        magick "$selected_path" \
            \( -clone 0 -channel R -separate -roll +15+0 \) \
            \( -clone 0 -channel G -separate \) \
            \( -clone 0 -channel B -separate -roll -15+0 \) \
            -channel RGB -combine "$EFFECT_FILE"
        ;;
    "CRT Retro")
        # Generates colored analog TV scanlines with chromatic aberration (glitch)
        magick "$selected_path" \
            \( -clone 0 -channel R -separate -roll +5+0 \) \
            \( -clone 0 -channel G -separate \) \
            \( -clone 0 -channel B -separate -roll -5+0 \) \
            -delete 0 -channel RGB -combine \
            -modulate 100,120,100 \
            \( -clone 0 -tile pattern:horizontal2 -draw "color 0,0 reset" \) \
            -compose multiply -composite "$EFFECT_FILE"
        ;;
    "Noir (High Contrast)")
        magick "$selected_path" -colorspace gray -contrast-stretch 5%x5% "$EFFECT_FILE"
        ;;
    "Pixelate")
        magick "$selected_path" -scale 5% -scale 2000% "$EFFECT_FILE"
        ;;
    "Vignette")
        magick "$selected_path" -background black -vignette 0x60 "$EFFECT_FILE"
        ;;
esac

echo "$EFFECT_FILE" > "$HOME/.config/wallpapers/.current_effect_image"
~/.config/hypr/scripts/wallpaper-selector.sh --set "$EFFECT_FILE"
