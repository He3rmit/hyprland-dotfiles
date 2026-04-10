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

# Helpers for Lastimosa V2 Optics (Pilot Helmet)
generate_hex_tile() {
    local color="$1"
    # Create a small hexagonal honeycomb tile
    magick -size 20x34 xc:none -stroke "$color" -strokewidth 1 -fill none \
        -draw "path 'M 0,0 L 10,6 L 20,0 M 0,34 L 10,28 L 20,34 M 10,6 L 10,28'" "$GRID_TILE"
}

apply_helmet_optics() {
    local input="$1"
    local output="$2"
    local color="#00E0FF" # Cyan-White Pilot HUD
    
    local w=$(magick identify -format "%w" "$input")
    local h=$(magick identify -format "%h" "$input")
    local half_w=$((w/2))
    local half_h=$((h/2))
    
    # 1. Draw Data Bars (Top/Bottom Compass) and BT-7274 Reticle
    # Top Bar: y=40, Bottom Bar: y=H-40
    # Central Reticle: 160x100 brackets around center
    local rw=80  # Reticle half-width
    local rh=50  # Reticle half-height
    local rl=30  # Reticle corner length
    
    magick "$input" -stroke "$color" -strokewidth 2 -fill none \
        -draw "line 400,40 $((w-400)),40" \
        -draw "line 400,$((h-40)),$((w-400)),$((h-40))" \
        -draw "line $((half_w-rw)),$((half_h-rh)) $((half_w-rw+rl)),$((half_h-rh)) line $((half_w-rw)),$((half_h-rh)) $((half_w-rw)),$((half_h-rh+rl))" \
        -draw "line $((half_w+rw)),$((half_h-rh)) $((half_w+rw-rl)),$((half_h-rh)) line $((half_w+rw)),$((half_h-rh)) $((half_w+rw)),$((half_h-rh+rl))" \
        -draw "line $((half_w-rw)),$((half_h+rh)) $((half_w-rw+rl)),$((half_h+rh)) line $((half_w-rw)),$((half_h+rh)) $((half_w-rw)),$((half_h+rh-rl))" \
        -draw "line $((half_w+rw)),$((half_h+rh)) $((half_w+rw-rl)),$((half_h+rh)) line $((half_w+rw)),$((half_h+rh)) $((half_w+rw)),$((half_h+rh-rl))" \
        "$CACHE_DIR/optics_flat.jpg"

    # 2. Apply Barrel Distortion (Curved Visor)
    # A=0, B=0.04 (Bulge), C=0, D=0.96 (Zoom to hide edges)
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
