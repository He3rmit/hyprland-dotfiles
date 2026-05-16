#!/usr/bin/env bash

# 🚀 Pilot HUD — Tactical Emoji Engine (v1.3.0)
# Unified high-speed text-based selector.

EMOJI_LIST=(
    "😀 Smileys" "😂 Laughing" "🤣 RoFL" "😊 Happy" "😇 Angel" "😍 Heart-Eyes" "🤩 Star-Struck"
    "🤔 Thinking" "🤨 Skeptical" "🙄 Rolling-Eyes" "😬 Grimacing" "🤥 Liar" "😴 Sleeping"
    "😎 Cool" "🤓 Nerd" "🧐 Monocle" "🥳 Party" "🤠 Cowboy" "🤡 Clown"
    "🤝 Handshake" "👍 Thumbs-UP" "👎 Thumbs-Down" "👊 Punch" "👌 OK" "🤞 Fingers-Crossed"
    "❤️ Heart" "💔 Broken" "🔥 Fire" "🚀 Rocket" "🛰️ Satellite" "🛡️ Shield" "🦾 Bionic"
    "✨ Sparkles" "⭐ Star" "💡 Idea" "💎 Gem" "🎯 Bullseye" "✅ Check" "❌ Cross"
    "🏁 Finish" "⚠️ Alert" "🛑 Stop" "⚙️ Gear" "🔧 Wrench" "💻 Terminal" "💾 Save"
    "🎮 Gaming" "🎵 Music" "🎥 Cinematic" "📸 Capture" "🌈 Prismatic" "🪐 Saturn" "🌌 Galaxy"
)

# Convert list to Rofi input
MENU=$(printf "%s\n" "${EMOJI_LIST[@]}")

# Launch Rofi
SELECTED=$(echo -e "$MENU" | rofi -dmenu -i -p "󰞅 Tactical Emoji" -theme-str 'listview { columns: 2; }')

if [ -n "$SELECTED" ]; then
    # Extract just the emoji (first character)
    EMOJI=$(echo "$SELECTED" | awk '{print $1}')
    
    # Copy to clipboard
    echo -n "$EMOJI" | wl-copy
    
    # Notify Pilot
    notify-send -t 2000 -a "Pilot HUD" "󰞅 Emoji Copied" "$EMOJI Has been cached for deployment."
fi
