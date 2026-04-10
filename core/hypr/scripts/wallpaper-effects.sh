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
EFFECTS="Original\n[ PILOT VISION ]\nBloom (Cinematic)\nVanguard Tactical (Orange/Green)\nBT-7274 Thermal (Red/Yellow)\nCyber HUD (Cyan/Magenta)\nNight Vision\n-\n[ DIGITAL MODES ]\nGlitch (Purge)\nCRT Retro\nNoir (High Contrast)\nPixelate\nVignette"
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

# Helper for Dynamic Scaling
# All geometry is calculated relative to a reference resolution
get_geometry() {
    local input="$1"
    W=$(magick identify -format "%w" "$input")
    H=$(magick identify -format "%h" "$input")
    
    # Scale factor relative to 1920px width
    SCALE=$(awk "BEGIN {print $W / 1920}")
    
    # HUD Geometry
    HALF_W=$((W/2))
    HALF_H=$((H/2))
    
    # Reticle (Centered)
    RW=$(awk "BEGIN {print int(40 * $SCALE)}")
    RH=$(awk "BEGIN {print int(25 * $SCALE)}")
    RL=$(awk "BEGIN {print int(15 * $SCALE)}")
    
    # Data Bars (Top/Bottom)
    BAR_Y=$(awk "BEGIN {print int(40 * $SCALE)}")
    BAR_MARGIN=$(awk "BEGIN {print int(300 * $SCALE)}")
}

apply_helmet_optics() {
    local input="$1"
    local output="$2"
    local color="#00E0FF" # Cyan-White Pilot HUD
    
    get_geometry "$input"
    
    magick "$input" -stroke "$color" -strokewidth 2 -fill none \
        -draw "line $BAR_MARGIN,$BAR_Y $((W-BAR_MARGIN)),$BAR_Y" \
        -draw "line $BAR_MARGIN,$((H-BAR_Y)),$((W-BAR_MARGIN)),$((H-BAR_Y))" \
        -draw "line $((HALF_W-RW)),$((HALF_H-RH)) $((HALF_W-RW+RL)),$((HALF_H-RH)) line $((HALF_W-RW)),$((HALF_H-RH)) $((HALF_W-RW)),$((HALF_H-RH+RL))" \
        -draw "line $((HALF_W+RW)),$((HALF_H-RH)) $((HALF_W+RW-RL)),$((HALF_H-RH)) line $((HALF_W+RW)),$((HALF_H-RH)) $((HALF_W+RW)),$((HALF_H-RH+RL))" \
        -draw "line $((HALF_W-RW)),$((HALF_H+RH)) $((HALF_W-RW+RL)),$((HALF_H+RH)) line $((HALF_W-RW)),$((HALF_H+RH)) $((HALF_W-RW)),$((HALF_H+RH-RL))" \
        -draw "line $((HALF_W+RW)),$((HALF_H+RH)) $((HALF_W+RW-RL)),$((HALF_H+RH)) line $((HALF_W+RW)),$((HALF_H+RH)) $((HALF_W+RW)),$((HALF_H+RH-RL))" \
        "$CACHE_DIR/optics_flat.jpg"

    # 2. Apply Barrel Distortion (Curved Visor) - Baseline values
    magick "$CACHE_DIR/optics_flat.jpg" -virtual-pixel transparent -distort Barrel "0.0 0.04 0.0 0.96" "$output"
}

case "$selected_effect" in
    "Bloom (Cinematic)")
        # Cinematic Bloom V2: Catching more highlights with a wider, softer lens glow
        magick "$selected_path" \( +clone -level 20,100% -blur 0x25 -modulate 100,120,100 \) -compose Screen -composite "$EFFECT_FILE"
        ;;
    "Vanguard Tactical (Orange/Green)")
        # Lastimosa V2: Curved Visor + Teal/Orange + Subtle Ghost Hex + Reticle
        generate_hex_tile "rgba(0,224,255,0.1)" # Even more subtle
        magick "$selected_path" -modulate 100,120,100 +level-colors "#1A2F1A","#E55A00" \
            \( -clone 0 -tile "$GRID_TILE" -draw "color 0,0 reset" \) -compose Overlay -composite "$CACHE_DIR/temp_base.jpg"
        apply_helmet_optics "$CACHE_DIR/temp_base.jpg" "$EFFECT_FILE"
        ;;
    "BT-7274 Thermal (Red/Yellow)")
        # BT Cockpit: Curved Visor + Red/Yellow + Scanlines + Reticle
        magick "$selected_path" -modulate 100,150,100 +level-colors "#330000","#FFB400" \
            \( -clone 0 -tile pattern:horizontal2 -draw "color 0,0 reset" \) -compose multiply -composite "$CACHE_DIR/temp_base.jpg"
        apply_helmet_optics "$CACHE_DIR/temp_base.jpg" "$EFFECT_FILE"
        ;;
    "Cyber HUD (Cyan/Magenta)")
        # Digital Optics: Neon Purple + Sleek Scanlines + Cyan Glow + Reticle
        magick "$selected_path" -modulate 110,140,100 +level-colors "#1B032A","#00E0FF" \
            \( -clone 0 -tile pattern:horizontal2 -draw "color 0,0 reset" \) -compose Screen -composite "$CACHE_DIR/temp_base.jpg"
        apply_helmet_optics "$CACHE_DIR/temp_base.jpg" "$EFFECT_FILE"
        ;;
    "Night Vision")
        magick "$selected_path" -colorspace gray +level-colors "#061A06","#00FF33" \
            -modulate 100,150,100 -sharpen 0x2 "$EFFECT_FILE"
        ;;
    "Glitch (Purge)")
        # Dynamic Chromatic aberration shift based on width
        local w=$(magick identify -format "%w" "$selected_path")
        local shift=$(awk "BEGIN {print int(15 * $w / 1920)}")
        magick "$selected_path" \
            \( -clone 0 -channel R -separate -roll +${shift}+0 \) \
            \( -clone 0 -channel G -separate \) \
            \( -clone 0 -channel B -separate -roll -${shift}+0 \) \
            -channel RGB -combine "$EFFECT_FILE"
        ;;
    "CRT Retro")
        # Generates colored analog TV scanlines with dynamic shift
        local w=$(magick identify -format "%w" "$selected_path")
        local shift=$(awk "BEGIN {print int(5 * $w / 1920)}")
        magick "$selected_path" \
            \( -clone 0 -channel R -separate -roll +${shift}+0 \) \
            \( -clone 0 -channel G -separate \) \
            \( -clone 0 -channel B -separate -roll -${shift}+0 \) \
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
        # Baseline vignette with dynamic intensity scaling
        local w=$(magick identify -format "%w" "$selected_path")
        local v_sigma=$(awk "BEGIN {print int(60 * $w / 3200)}")
        magick "$selected_path" -background black -vignette 0x${v_sigma} "$EFFECT_FILE"
        ;;
esac

echo "$EFFECT_FILE" > "$HOME/.config/wallpapers/.current_effect_image"
~/.config/hypr/scripts/wallpaper-selector.sh --set "$EFFECT_FILE"
