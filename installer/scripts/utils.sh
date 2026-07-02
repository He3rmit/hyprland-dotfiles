#!/bin/bash

# --- PILOT UTILITIES ---

# Print a formatted step using gum (if available), otherwise fallback to standard echo
print_step() {
    if command -v gum &> /dev/null; then
        gum style --foreground 212 --bold "$1"
    else
        echo -e "\033[1;35m$1\033[0m"
    fi
}

print_success() {
    if command -v gum &> /dev/null; then
        gum style --foreground 46 --bold "✅ $1"
    else
        echo -e "\033[1;32m✅ $1\033[0m"
    fi
}

print_warning() {
    if command -v gum &> /dev/null; then
        gum style --foreground 214 --bold "⚠️  $1"
    else
        echo -e "\033[1;33m⚠️  $1\033[0m"
    fi
}

print_error() {
    if command -v gum &> /dev/null; then
        gum style --foreground 196 --bold "❌ $1"
    else
        echo -e "\033[1;31m❌ $1\033[0m"
    fi
}

# Safety Protocol: Backup existing files before symlinking
safe_link() {
    local source="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        # It's already a symlink, just replace it
        rm "$target"
    elif [ -e "$target" ]; then
        # It's a real file, back it up
        print_warning "Existing file detected at $target. Creating backup (.bak)"
        mv "$target" "${target}.bak"
    fi
    ln -s "$source" "$target"
    # echo "Linked: $source -> $target"
}

# HUD Verification: Check for necessary fonts to avoid "?" icons
check_fonts() {
    local font_name="ShureTechMono Nerd Font"
    if ! fc-list : family | grep -iq "$font_name"; then
        print_error "WARNING: $font_name not found. Workspace icons may show as '?'"
        echo "💡 Hint: Install the font from your dotfiles or AUR."
    else
        print_success "Font $font_name verified. HUD icons nominal."
    fi
}

# Ensure Sudo is active for the script execution
keep_sudo_alive() {
    print_step "Initializing Pilot Authorization..."
    sudo -v
    while true; do 
        sudo -nv
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# Bootstrap an AUR helper (yay or paru) if neither is installed
bootstrap_aur_helper() {
    if command -v yay &> /dev/null || command -v paru &> /dev/null; then
        return 0
    fi

    print_warning "No AUR helper (yay or paru) detected."
    
    # We need git and base-devel to build from AUR
    print_step "Ensuring 'git' and 'base-devel' are installed..."
    sudo pacman -S --noconfirm --needed git base-devel

    local helper="yay"
    if command -v gum &> /dev/null; then
        print_step "Select an AUR helper to install:"
        helper=$(gum choose "yay" "paru")
    else
        echo "Which AUR helper would you like to install?"
        echo "1) yay (recommended)"
        echo "2) paru"
        if [ -t 0 ]; then
            read -rp "Enter choice [1-2]: " choice
            case "$choice" in
                2) helper="paru" ;;
                *) helper="yay" ;;
            esac
        else
            echo "Non-interactive terminal detected. Defaulting to yay."
            helper="yay"
        fi
    fi

    print_step "Bootstrapping $helper from AUR..."
    local temp_dir
    temp_dir=$(mktemp -d /tmp/aur_helper_bootstrap.XXXXXX)
    
    # Git clone the -bin package for faster compilation
    local pkg_name="${helper}-bin"
    
    if ! git clone "https://aur.archlinux.org/${pkg_name}.git" "$temp_dir/$pkg_name"; then
        print_warning "Failed to clone $pkg_name. Trying source version..."
        pkg_name="$helper"
        git clone "https://aur.archlinux.org/${pkg_name}.git" "$temp_dir/$pkg_name"
    fi

    # Enter directory and build
    (
        cd "$temp_dir/$pkg_name" || exit 1
        makepkg -si --noconfirm
    )

    local build_status=$?
    rm -rf "$temp_dir"

    if [ $build_status -eq 0 ] && command -v "$helper" &> /dev/null; then
        print_success "$helper successfully bootstrapped."
        return 0
    else
        print_error "Failed to install $helper."
        return 1
    fi
}

# Distro-Agnostic Package Installation (Pacman -> Yay/Paru)
aur_install() {
    local pkg="$1"
    
    # Try official repos first using sudo pacman
    if sudo pacman -Sp "$pkg" &>/dev/null; then
        sudo pacman -S --noconfirm --needed "$pkg"
        return $?
    fi

    # Fallback to AUR helpers
    if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
        bootstrap_aur_helper || return 1
    fi

    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed "$pkg"
    elif command -v paru &> /dev/null; then
        paru -S --noconfirm --needed "$pkg"
    else
        print_error "AUR Helper (yay or paru) not found! Cannot install: $pkg"
        return 1
    fi
}

