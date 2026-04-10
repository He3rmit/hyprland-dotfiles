#!/bin/bash
# ==============================================================================
# TITANFALL PILOT HUD — EJECT PROTOCOL (v1.1.0)
# Purpose: Safely remove all dotfile symlinks, caches, overrides, and
#          optionally uninstall non-default packages.
# ==============================================================================

cd "$(dirname "$0")" || exit 1
INSTALLER_DIR=$(pwd)
DOTFILES_DIR=$(dirname "$INSTALLER_DIR")
source "$INSTALLER_DIR/scripts/utils.sh"

# ── 0. ENSURE GUM ──────────────────────────────────────────────────────────────
if ! command -v gum &> /dev/null; then
    echo "gum is required for this UI. Install it with: paru -S gum"
    exit 1
fi

clear

# ── 1. SPLASH SCREEN ──────────────────────────────────────────────────────────
gum style \
    --border double \
    --border-foreground 196 \
    --foreground 196 \
    --bold \
    --margin "1 4" \
    --padding "1 8" \
    "███████╗     ██╗███████╗ ██████╗████████╗" \
    "██╔════╝     ██║██╔════╝██╔════╝╚══██╔══╝" \
    "█████╗       ██║█████╗  ██║        ██║   " \
    "██╔══╝  ██   ██║██╔══╝  ██║        ██║   " \
    "███████╗╚█████╔╝███████╗╚██████╗   ██║   " \
    "╚══════╝ ╚════╝ ╚══════╝ ╚═════╝   ╚═╝   "

gum style \
    --foreground 244 \
    --align center \
    --margin "0 4" \
    "PILOT HUD  //  EJECT PROTOCOL  //  v1.1.0"

echo ""

# ── 2. AUTHORIZATION ──────────────────────────────────────────────────────────
gum style --foreground 214 --bold "[ PILOT AUTHORIZATION ]"
keep_sudo_alive

# ── 3. MODULE SELECTION ───────────────────────────────────────────────────────
echo ""
gum style --foreground 51 --bold "Select Eject Modules:"
gum style --foreground 244 \
    "  Unstow Configs           — Remove all symlinks from ~/.config and ~/" \
    "  Clean Pilot & Wal Cache  — Purge all wallpaper/effect/color caches" \
    "  Clean Wireplumber        — Remove audio config overrides" \
    "  Clean SDDM Theme         — Remove cinematic login override" \
    "  Uninstall Core Rice      — Remove WM (Hyprland), bars, and rice tools" \
    "  Uninstall Extra Apps     — Remove Kitty, Alacritty, Dolphin, Ark, etc." \
    "  Uninstall Gum Engine     — Purge the UI tool itself after sign-off" \
    "  FULL PURGE               — Everything (Except system-critical items)"
echo ""
gum style --foreground 244 "(SPACE to select, ENTER to confirm)"
echo ""

MODULES=$(gum choose --no-limit \
    "Unstow Configs" \
    "Clean Pilot & Wal Cache" \
    "Clean Wireplumber" \
    "Clean SDDM Theme" \
    "Uninstall Core Rice" \
    "Uninstall Extra Apps" \
    "Uninstall Gum Engine" \
    "FULL PURGE")

if [ -z "$MODULES" ]; then
    print_warning "No modules selected. Eject aborted."
    exit 0
fi

# Check for Full Purge
FULL_EJECT=false
[[ "$MODULES" == *"FULL PURGE"* ]] && FULL_EJECT=true

echo ""
gum style --foreground 196 --bold "Initiating Eject Protocol..."
if ! gum confirm --prompt.foreground 196 "Are you absolutely sure, Pilot?"; then
    print_warning "Eject aborted."
    exit 0
fi

# ── 4. HELPER: Remove symlink safely ─────────────────────────────────────────
remove_link() {
    local target="$1"
    if [ -L "$target" ]; then
        rm "$target"
        echo "  🗑️  Removed symlink: $target"
    elif [ -f "$target" ]; then
        rm "$target"
        echo "  🗑️  Removed file: $target"
    fi
}

# ── 5. UNSTOW CONFIGS ────────────────────────────────────────────────────────
if [[ "$MODULES" == *"Unstow Configs"* ]] || [ "$FULL_EJECT" = true ]; then
    print_step ">> Ejecting Stowed Configurations..."

    cd "$DOTFILES_DIR" || exit 1
    stow -D -t "$HOME" home 2>/dev/null
    stow -D -t "$HOME/.config" core 2>/dev/null
    stow -D -t "$HOME/.config/hypr" hyprland 2>/dev/null

    print_step ">> Removing explicit symlinks..."
    remove_link "$HOME/.config/hypr/host.conf"
    remove_link "$HOME/.config/kitty/host.conf"
    remove_link "$HOME/.config/swaync/config.json"
    remove_link "$HOME/.config/waybar/config.jsonc"
    remove_link "$HOME/.config/waybar/style.css"
    remove_link "$HOME/.config/hypr/modules/monitor.conf"
    remove_link "$HOME/.config/hypr/modules/user-keybinds.conf"
    remove_link "$HOME/.config/hypr/modules/hypr-host.conf"
    remove_link "$HOME/.zshrc.local"

    print_step ">> Removing generated state files..."
    remove_link "$HOME/.config/hypr/touchpad.conf"
    remove_link "$HOME/.config/hypr/modules/colors.conf"
    remove_link "$HOME/.config/wallpapers/.current_wallpaper"
    rm -f "$HOME/.config/wallpapers/.current_effect_image"

    # Restore a minimal .zshrc
    if [ ! -f "$HOME/.zshrc" ]; then
        print_step ">> Restoring minimal .zshrc fallback..."
        cat > "$HOME/.zshrc" << 'FALLBACK'
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f$ '
export EDITOR=nano
FALLBACK
    fi
fi

# ── 6. CLEAN CACHES ──────────────────────────────────────────────────────────
if [[ "$MODULES" == *"Clean Pilot & Wal Cache"* ]] || [ "$FULL_EJECT" = true ]; then
    print_step ">> Purging Framework Caches..."
    rm -rf "$HOME/.cache/wal" 2>/dev/null
    rm -rf "$HOME/.cache/wallpaper-thumbnails" 2>/dev/null
    rm -rf "$HOME/.cache/waybar" 2>/dev/null
    rm -rf /tmp/cliphist-thumbnails 2>/dev/null
    echo "  🗑️  Cleaned all Pilot Vision and color caches."
fi

# ── 7. CLEAN WIREPLUMBER ─────────────────────────────────────────────────────
if [[ "$MODULES" == *"Clean Wireplumber"* ]] || [ "$FULL_EJECT" = true ]; then
    print_step ">> Removing Wireplumber overrides..."
    WP_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
    remove_link "$WP_DIR/50-common-priorities.conf"
    remove_link "$WP_DIR/51-host-rescue.conf"
    systemctl --user stop wireplumber 2>/dev/null
    rm -rf ~/.local/state/wireplumber/* 2>/dev/null
    systemctl --user start wireplumber 2>/dev/null
fi

# ── 8. CLEAN SDDM THEME ──────────────────────────────────────────────────────
if [[ "$MODULES" == *"Clean SDDM Theme"* ]] || [ "$FULL_EJECT" = true ]; then
    print_step ">> Disengaging Cinematic SDDM Protocol..."
    sudo rm -f "/etc/sddm.conf.d/00-theme.conf" 2>/dev/null
    sudo rm -f "/usr/share/sddm/themes/sddm-astronaut-theme/Movies/titanfall_intro_cinematic.mp4" 2>/dev/null
    sudo rm -f "/usr/share/sddm/themes/sddm-astronaut-theme/theme.conf.user" 2>/dev/null
    print_success "SDDM reverted."
fi

# ── 9. UNINSTALL PACKAGES ────────────────────────────────────────────────────
REMOVABLE_CORE=(
    "hyprland" "xdg-desktop-portal-hyprland" "hypridle" "hyprlock" "hyprpicker" "hyprsunset" 
    "waybar" "swaync" "rofi" "wlogout" "wl-clipboard" "cliphist" "wtype" "grim" "slurp" "swappy" 
    "swaybg" "mpvpaper" "python-pywal" "xorg-xrdb" "nwg-look" "starship" "fastfetch" "gsimplecal"
    "qt5-graphicaleffects" "qt5-quickcontrols2" "qt5-svg" "nss-mdns" "ttf-orbitron" "obsidian-icon-theme"
)

EXTRA_APPS=(
    "kitty" "alacritty" "dolphin" "ark" "gvfs" "kio-admin" "kio-extras" "ffmpegthumbs" 
    "kdegraphics-thumbnailers" "ffmpegthumbnailer" "baloo-widgets" "taglib"
)

if [[ "$MODULES" == *"Uninstall Core Rice"* ]] || [ "$FULL_EJECT" = true ]; then
    print_step ">> Removing Core Rice Components..."
    for pkg in "${REMOVABLE_CORE[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            echo "  📦 Removing: $pkg"
            sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null
        fi
    done
fi

if [[ "$MODULES" == *"Uninstall Extra Apps"* ]] || [ "$FULL_EJECT" = true ]; then
    print_step ">> Analyzing Extra Apps for removal..."
    if pacman -Qi "plasma-desktop" &>/dev/null; then
        print_warning "KDE Plasma detected. Protecting shared apps (Dolphin, Ark, etc.)."
        TARGET_EXTRAS=("kitty" "alacritty")
    else
        TARGET_EXTRAS=("${EXTRA_APPS[@]}")
    fi

    for pkg in "${TARGET_EXTRAS[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            echo "  📦 Removing extra: $pkg"
            sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null
        fi
    done
fi

# ── 10. SIGN-OFF & GUM PURGE ──────────────────────────────────────────────────
echo ""
gum style \
    --border rounded --border-foreground 214 --foreground 214 --bold \
    --padding "1 4" --margin "1 2" \
    "EJECT COMPLETE" "Welcome to your clean slate, Pilot."

if [[ "$MODULES" == *"Uninstall Gum Engine"* ]] || [ "$FULL_EJECT" = true ]; then
    echo ">> Final Sweep: Removing Gum Engine..."
    # This must be the very last command.
    sleep 1 && sudo pacman -Rns --noconfirm gum 2>/dev/null &
fi
