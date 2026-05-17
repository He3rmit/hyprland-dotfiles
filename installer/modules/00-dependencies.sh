#!/bin/bash
# ==============================================================================
# MODULE: 00-dependencies.sh
# Purpose: Installs core system dependencies early on. This checklist ensures
#          a "Pure Hyprland" install has everything it needs (like polkit)
#          even if run on a base Arch Linux install without KDE Plasma.
# ==============================================================================

source "$INSTALLER_DIR/scripts/utils.sh"

print_step "Validating Core Dependencies for Pure Hyprland..."

# Core packages needed regardless of base environment
CORE_PACKAGES=(
    # --- CORE INSTALLER DEPS ---
    "stow"
    "yay"
    "less" # for yay diff build
    "paru"
    
    # --- HYPRLAND SYSTEM DEPS ---
    "hyprland"
    "xdg-desktop-portal"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"  # Essential for file pickers & settings
    "xwaylandvideobridge"     # Allows screen sharing for X11 apps like Discord
    "qt5-wayland"
    "qt6-wayland"
    "qt5-graphicaleffects"    # Required for SDDM themes visuals
    "qt5-quickcontrols2"     # Required for SDDM theme inputs
    "qt5-svg"                # Required for icon rendering in themes
    "nwg-look"
    "nss-mdns"                # Required for local hostname resolution (.local)
    
    # --- GUI COMPONENTS ---
    "waybar"
    "swaync"
    "rofi"
    "kitty"
    "thunar"
    "thunar-archive-plugin"
    "thunar-volman"
    "tumbler"                 # Thunar thumbnails
    "gvfs"                    # File manager trash & mount support
    "file-roller"             # Archives (zip/unzip from GUI)
    "ffmpegthumbnailer"       # Rofi video thumbnails
    "micro"                    # Lightweight terminal text editor
    "mpv"                     # Video wallpaper playback
    "ffmpeg"                  # General multimedia support
    "btop"                    # System Monitor for SwayNC
    
    # --- HYPRLAND DAEMONS & SYSTEM UTILS ---
    "hypridle"
    "hyprlock"
    "hyprpicker"
    "hyprsunset"
    "wlogout"
    "wl-clipboard"
    "cliphist"
    "libnotify"
    "xorg-xhost"
    "xdg-user-dirs"
    "imagemagick"             # Required by cliphist-rofi for image previews
    "wtype"                   # Required by cliphist-rofi for auto-typing
    "python-pywal"            # Global Theming Engine (Extracts wallpaper colors)
    "xorg-xrdb"               # Required by Pywal (even on Wayland)
    "python-requests"         # Required for Media Hub (Hydra)
    "python-gobject"          # Required for Media Hub (Hydra) GTK
    "gtk3"                    # Required for Media Hub GTK
    "gsimplecal"

    # --- SHELL ---
    "zsh"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "zsh-history-substring-search"
    
    # --- SCREENSHOT & WALLPAPER ---
    "grim"
    "slurp"
    "swappy"
    "swaybg"
    "mpvpaper"
    "jq"
    
    # --- HARDWARE CONTROL ---
    "upower"
    "brightnessctl"
    "power-profiles-daemon"
    "playerctl"
    "networkmanager"
    "network-manager-applet"
    "nm-connection-editor"
    "wev" # for keybinds troubleshooting
    # --- CORE UTILITIES ---
    "unzip"
    "wget"
    "curl"
    "xdg-utils"
    
    # --- AUDIO & BLUETOOTH ---
    "wireplumber"
    "pipewire"
    "pipewire-pulse"
    "pavucontrol"
    "linux-wifi-hotspot"
    "bluez"                   # Bluetooth Engine
    "bluez-utils"             # Bluetooth CLI (bluetoothctl)
    "blueman"
    
    # --- THEME & FONTS ---
    "ttf-sharetech-mono-nerd"
    "ttf-jetbrains-mono-nerd"
    "ttf-nerd-fonts-symbols"
    "ttf-orbitron"
    "noto-fonts-emoji"
    "obsidian-icon-theme"
    "adwaita-icon-theme"
    "breeze-icons"
    "orchis-theme"
    "starship"
    "fastfetch"
)

# Fallback packages only needed if we are NOT running alongside KDE Plasma
STANDALONE_PACKAGES=(
    "hyprpolkitagent" # Native Hyprland polkit agent for sudo prompts in GUI apps
    "gnome-keyring"   # Required for managing secrets/passwords
    "sddm"            # Display Manager
)

# Function to check and install
install_pkg() {
    local pkg=$1
    if ! pacman -Qi "$pkg" &> /dev/null && ! pacman -Qq "$pkg" &> /dev/null; then
        echo "Installing $pkg..."
        aur_install "$pkg"
    else
        echo "✅ $pkg is already installed."
    fi
}

print_step "Installing Core Packages..."
for pkg in "${CORE_PACKAGES[@]}"; do
    install_pkg "$pkg"
done

# --- GPU HARDWARE TRINITY (Acceleration Essentials) ---
if lspci | grep -qi "nvidia"; then
    print_warning "NVIDIA GPU detected. Enhancing with hardware acceleration..."
    install_pkg "nvidia-utils"
    install_pkg "libva-nvidia-driver"
    install_pkg "nvidia-settings"
    print_success "NVIDIA Essentials deployed."
elif lspci | grep -qi "intel"; then
    print_warning "Intel GPU detected. Enhancing with low-latency acceleration..."
    install_pkg "lib32-vulkan-intel"
    install_pkg "vulkan-intel"
    install_pkg "intel-media-driver"
    install_pkg "libva-intel-driver"
    print_success "Intel Essentials deployed."
elif lspci | grep -qi "amd" || lspci | grep -qi "ati"; then
    print_warning "AMD GPU detected. Enhancing with Vulkan & VA-API..."
    install_pkg "lib32-vulkan-radeon"
    install_pkg "vulkan-radeon"
    install_pkg "libva-mesa-driver"
    install_pkg "mesa-vdpau"
    print_success "AMD Essentials deployed."
fi

# Smart Detection: Are we running alongside Plasma?
if pacman -Qi "plasma-desktop" &> /dev/null; then
    print_success "KDE Plasma detected. Skipping redundant daemons (Polkit, Keyring)."
else
    print_warning "Naked Arch install detected. Installing standalone daemons..."
    for pkg in "${STANDALONE_PACKAGES[@]}"; do
        install_pkg "$pkg"
    done
fi

# Rebuild font cache after installing all font packages
print_step ">> Rebuilding font cache..."
fc-cache -fv > /dev/null 2>&1

# Apply Orchis-Dark as the global GTK default (project standard theme)
print_step ">> Applying Orchis-Dark as default GTK theme..."
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
[ -f "$HOME/.config/gtk-3.0/settings.ini" ] && sed -i 's/^gtk-theme-name=.*/gtk-theme-name=Orchis-Dark/' "$HOME/.config/gtk-3.0/settings.ini"
[ -f "$HOME/.config/gtk-4.0/settings.ini" ] && sed -i 's/^gtk-theme-name=.*/gtk-theme-name=Orchis-Dark/' "$HOME/.config/gtk-4.0/settings.ini"
print_success "GTK theme set to Orchis-Dark."

print_success "Dependencies nominal. System is ready for deployment."
