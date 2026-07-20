#!/bin/bash
# ==============================================================================
# MODULE: 01-stow-configs.sh
# Purpose: Dynamically creates target directories, stows dotfiles safely,
#          and bootstraps first-run requirements (pywal, touchpad, shell.local).
# ==============================================================================

source "$INSTALLER_DIR/scripts/utils.sh"

# Source profile metadata if available
if [[ -f "$DOTFILES_DIR/hosts/$TARGET/profile.conf" ]]; then
    source "$DOTFILES_DIR/hosts/$TARGET/profile.conf"
fi

export KB_CONF="$HOME/.config/hypr/modules/keyboard.lua"

print_step "Stowing configurations..."

# 1. Link Home Files (No --adopt, safer)
print_step ">> Stowing Home Directory Files..."
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    print_warning "Real .zshrc detected. Backing up to .zshrc.bak..."
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
fi
cd "$DOTFILES_DIR" || exit 1
stow -v -R --no-folding -t "$HOME" home || { print_error "Failed to stow home directory!"; exit 1; }

# 2. Dynamic Target Creation for Core
# This prevents GNU Stow from "folding" an entire directory if the target 
# doesn't exist, which causes conflicts later. We create every top-level 
# directory found in core/ inside ~/.config first.
print_step ">> Preparing ~/.config for Core Apps..."
find "$DOTFILES_DIR/core" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | while read -r dir; do
    mkdir -p "$HOME/.config/$dir"
done

# PRE-STOW SWEEPER: Remove generated caches and explicit overrides that block GNU Stow
print_step ">> Sweeping pre-existing core conflicts..."
rm -f "$HOME/.config/swaync/config.json"
rm -f "$HOME/.config/waybar/config.jsonc"
rm -f "$HOME/.config/waybar/style.css"
rm -f "$HOME/.config/wireplumber/wireplumber.conf.d/51-host-rescue.conf"
rm -rf "$HOME/.config/wallpapers"

print_step ">> Stowing Core Configs..."
stow -v -R --no-folding -t "$HOME/.config" core || { print_error "Failed to stow core directory!"; exit 1; }

# 3. Handle Host-Specific Config Overrides (Dynamic Engine)
print_step ">> Applying Global Intelligence with Host Overrides for $TARGET..."

# Always link the core config first as a universal baseline
safe_link "$DOTFILES_DIR/core/swaync/config.json" "$HOME/.config/swaync/config.json"

# Dynamically link any XDG overrides found in the host vault
HOST_CONFIG_DIR="$DOTFILES_DIR/hosts/$TARGET/.config"
if [[ -d "$HOST_CONFIG_DIR" ]]; then
    print_step ">> Deploying dynamic XDG overrides from host vault..."
    find "$HOST_CONFIG_DIR" -type f | while read -r override_file; do
        rel_path="${override_file#$HOST_CONFIG_DIR/}"
        target_path="$HOME/.config/$rel_path"
        mkdir -p "$(dirname "$target_path")"
        safe_link "$override_file" "$target_path"
    done
fi

# 4. Link Hyprland Environment
# PRE-STOW SWEEPER: Remove explicit overrides that block GNU Stow from deploying hyprland
print_step ">> Sweeping pre-existing hyprland conflicts..."
rm -f "$HOME/.config/hypr/host.lua"
rm -f "$HOME/.config/hypr/hypridle-host.conf"
rm -f "$HOME/.config/hypr/hyprlock-host.conf"
rm -f "$HOME/.config/hypr/hyprsunset.conf"
rm -f "$HOME/.config/hypr/user-keybinds.lua"
rm -f "$HOME/.config/hypr/user-windowrules.lua"
rm -f "$HOME/.config/hypr/user-visuals.lua"
rm -f "$HOME/.config/hypr/hyprland.lua"

print_step ">> Stowing Hyprland Environment..."
stow -v -R --no-folding -t "$HOME/.config/hypr" hyprland || { print_error "Failed to stow hyprland directory!"; exit 1; }

# Atomically link hyprland.lua to defeat the race condition
print_step ">> Atomically linking Hyprland main config..."
ln -s "$DOTFILES_DIR/hyprland/hyprland.lua" "$HOME/.config/hypr/hyprland.lua.tmp"
mv -T "$HOME/.config/hypr/hyprland.lua.tmp" "$HOME/.config/hypr/hyprland.lua"

# Helper to link or touch required source files
link_or_touch() {
    local source_file="$1"
    local target_file="$2"
    if [[ -f "$source_file" ]]; then
        safe_link "$source_file" "$target_file"
    else
        touch "$target_file"
    fi
}

link_or_touch "$DOTFILES_DIR/hosts/$TARGET/hypr-host.lua" "$HOME/.config/hypr/host.lua"
link_or_touch "$DOTFILES_DIR/hosts/$TARGET/hypridle-host.conf" "$HOME/.config/hypr/hypridle-host.conf"
link_or_touch "$DOTFILES_DIR/hosts/$TARGET/hyprlock-host.conf" "$HOME/.config/hypr/hyprlock-host.conf"
link_or_touch "$DOTFILES_DIR/hosts/$TARGET/hyprsunset.conf" "$HOME/.config/hypr/hyprsunset.conf"
link_or_touch "$DOTFILES_DIR/hosts/$TARGET/kitty-host.conf" "$HOME/.config/kitty/host.conf"
# 5. Waybar Deployment
print_step ">> Initializing Waybar Protocol..."
check_fonts

# Dynamically link the starting layout and style based on the Host Profile metadata
HOST_WAYBAR_CONFIG="$DOTFILES_DIR/hosts/$TARGET/waybar/config.jsonc"
if [[ -f "$HOST_WAYBAR_CONFIG" ]]; then
    print_step ">> Linking Custom Host Waybar Layout..."
    safe_link "$HOST_WAYBAR_CONFIG" "$HOME/.config/waybar/config.jsonc"
elif [[ -n "$WAYBAR_LAYOUT" && -f "$DOTFILES_DIR/core/waybar/layouts/${WAYBAR_LAYOUT}.jsonc" ]]; then
    safe_link "$DOTFILES_DIR/core/waybar/layouts/${WAYBAR_LAYOUT}.jsonc" "$HOME/.config/waybar/config.jsonc"
else
    # Fallback if profile metadata is incomplete
    safe_link "$DOTFILES_DIR/core/waybar/layouts/2-Topbar-Detailed.jsonc" "$HOME/.config/waybar/config.jsonc"
fi

if [[ -n "$WAYBAR_STYLE" && -f "$DOTFILES_DIR/core/waybar/styles/${WAYBAR_STYLE}.css" ]]; then
    safe_link "$DOTFILES_DIR/core/waybar/styles/${WAYBAR_STYLE}.css" "$HOME/.config/waybar/style.css"
else
    safe_link "$DOTFILES_DIR/core/waybar/styles/5-Glass-Pill.css" "$HOME/.config/waybar/style.css"
fi

# Fix script permissions
chmod +x "$DOTFILES_DIR/core/waybar/scripts/"*.sh
chmod +x "$DOTFILES_DIR/hyprland/scripts/"*.sh
chmod +x "$DOTFILES_DIR/core/swaync/scripts/"*.sh

# 6. FIRST-RUN BOOTSTRAP — Touchpad State File
# The laptop hypr-host.lua requires touchpad.lua, which doesn't exist
# until the toggle script creates it. Create a sane default.
if [[ "$HAS_TOUCHPAD" == "true" ]]; then
    TOUCHPAD_CONF="$HOME/.config/hypr/touchpad.lua"
    if [[ ! -f "$TOUCHPAD_CONF" ]]; then
        print_step ">> Creating default touchpad state file..."
        cat > "$TOUCHPAD_CONF" << EOF
-- Auto-generated by installer — touchpad enabled by default
hl.device({
    name = "elan0300:00-04f3:3206-touchpad",
    enabled = true
})
EOF
    fi
fi

print_step ">> Configuring Hardware Modules (Keyboard & Monitor)..."

# Ensure target modules directory exists for hardware links
mkdir -p "$HOME/.config/hypr/modules"

# --- 7.1 KEYBOARD CONFIG ---
cat > "$KB_CONF" << EOF
-- Auto-generated by installer based on profile.conf
hl.config({
    input = {
        kb_layout = "${KB_LAYOUT:-us}",
        kb_variant = "${KB_VARIANT:-}"
    }
})
EOF

# --- 7.2 MONITOR CONFIG (Vault Link) ---
MONITOR_VAULT="$DOTFILES_DIR/hosts/$TARGET/monitor.lua"
if [[ -f "$MONITOR_VAULT" ]]; then
    print_step ">> Linking Host-Specific Monitor Calibration..."
    safe_link "$MONITOR_VAULT" "$HOME/.config/hypr/modules/monitor.lua"
else
    print_warning "No monitor calibration found in vault. Generating default fallback..."
    cat > "$HOME/.config/hypr/modules/monitor.lua" << EOF
-- FALLBACK MONITOR CONFIG
hl.monitor({
    output = "${MONITOR_NAME:-}",
    mode = "preferred",
    position = "auto",
    scale = "${SCALE:-1.0}"
})
EOF
fi

# --- 7.3 NVIDIA AUTO-DETECTION ---
if lspci | grep -i nvidia &>/dev/null; then
    print_step ">> NVIDIA GPU Detected. Commencing Hardware Alignment..."
    NVIDIA_VAULT="$DOTFILES_DIR/hosts/$TARGET/nvidia.lua"
    if [[ -f "$NVIDIA_VAULT" ]]; then
        safe_link "$NVIDIA_VAULT" "$HOME/.config/hypr/modules/nvidia.lua"
    else
        print_warning "NVIDIA hardware found but no nvidia.lua exists in your host vault!"
        # Create a blank fallback to prevent Hyprland source errors
        touch "$HOME/.config/hypr/modules/nvidia.lua"
    fi
else
    # Ensure the file exists to satisfy Hyprland's 'require' command if not NVIDIA
    touch "$HOME/.config/hypr/modules/nvidia.lua"
fi


# 8. FIRST-RUN BOOTSTRAP — Pywal Color Generation
# Rofi themes, Kitty, and Hyprland all import colors from ~/.cache/wal/
# which only exists after pywal runs at least once. Bootstrap it now.
DEFAULT_WALL="$DOTFILES_DIR/core/wallpapers/library/Jack-Cooper-BT-7274.jpg"

if [[ ! -f "$HOME/.cache/wal/colors.lua" ]] && command -v wal &>/dev/null; then
    print_step ">> Bootstrapping Pywal color scheme..."
    if [[ -f "$DEFAULT_WALL" ]]; then
        wal -q -n -i "$DEFAULT_WALL"
        # Copy the generated Hyprland color variables
        if [[ -f "$HOME/.cache/wal/colors.lua" ]]; then
            cp "$HOME/.cache/wal/colors.lua" "$HOME/.config/hypr/modules/colors.lua"
        fi
        
        # Save explicit wallpaper state using a universal path relative to HOME
        mkdir -p "$HOME/.config/wallpapers"
        echo "$HOME/.config/wallpapers/library/$(basename "$DEFAULT_WALL")" > "$HOME/.config/wallpapers/.current_wallpaper"
        rm -f "$HOME/.config/wallpapers/.current_effect_image"
        
        print_success "Pywal bootstrapped with default wallpaper."
    else
        print_warning "Default wallpaper not found. Pywal colors will be generated on first wallpaper selection."
    fi
else
    # Safeguard: Even if colors exist, ensure the state file exists for a fresh clone
    if [[ ! -f "$HOME/.config/wallpapers/.current_wallpaper" ]]; then
        mkdir -p "$HOME/.config/wallpapers"
        echo "$HOME/.config/wallpapers/library/$(basename "$DEFAULT_WALL")" > "$HOME/.config/wallpapers/.current_wallpaper"
    fi
    print_success "Pywal cache already exists. Skipping bootstrap."
fi

# Ensure colors.lua is deployed to hypr modules if it exists in the Pywal cache
if [[ -f "$HOME/.cache/wal/colors.lua" ]]; then
    cp "$HOME/.cache/wal/colors.lua" "$HOME/.config/hypr/modules/colors.lua"
fi

# 8. USER VAULT — Link personal modules (Keybinds, Rules, Visuals)
print_step ">> Linking user overrides for $TARGET..."
link_or_touch "$DOTFILES_DIR/hosts/$TARGET/user-keybinds.lua" "$HOME/.config/hypr/user-keybinds.lua"
link_or_touch "$DOTFILES_DIR/hosts/$TARGET/user-windowrules.lua" "$HOME/.config/hypr/user-windowrules.lua"
link_or_touch "$DOTFILES_DIR/hosts/$TARGET/user-visuals.lua" "$HOME/.config/hypr/user-visuals.lua"


# 9. SHELL PERSONALIZATION — Link host shell.local
SHELL_LOCAL="$DOTFILES_DIR/hosts/$TARGET/shell.local"
if [[ -f "$SHELL_LOCAL" ]]; then
    print_step ">> Linking shell personalization for $TARGET..."
    safe_link "$SHELL_LOCAL" "$HOME/.zshrc.local"
fi

# 10. WIREPLUMBER AUDIO PROTOCOL — Host Overrides & Cache Wipe
HOST_WP_CONFIG="$DOTFILES_DIR/hosts/$TARGET/wireplumber/51-host-rescue.conf"
if [[ -f "$HOST_WP_CONFIG" ]]; then
    print_step ">> Linking host-specific Wireplumber rescue config..."
    mkdir -p "$HOME/.config/wireplumber/wireplumber.conf.d"
    safe_link "$HOST_WP_CONFIG" "$HOME/.config/wireplumber/wireplumber.conf.d/51-host-rescue.conf"
fi

# We must clear the wireplumber cache regardless of whether a host config exists,
# so that the newly stowed universal 50-common-priorities.conf is recognized on first boot.
print_step ">> Clearing Wireplumber cache to force priority updates..."
systemctl --user stop wireplumber 2>/dev/null || true
rm -rf ~/.local/state/wireplumber/* 2>/dev/null || true
systemctl --user start wireplumber 2>/dev/null || true

# 9. Live Interface Reload
if pgrep Hyprland > /dev/null; then
    print_step ">> Reloading Hyprland interface elements..."
    hyprctl reload &> /dev/null
    
    # Force Kill & Restart Waybar
    pkill waybar || true
    waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" &> /dev/null &
    
    # Reload SwayNC
    if command -v swaync-client &> /dev/null; then
        swaync-client -rs &> /dev/null
    fi
fi

print_success "Configs Stowed Successfully."
