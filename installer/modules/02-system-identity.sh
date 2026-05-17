#!/bin/bash
# ==============================================================================
# MODULE: 02-system-identity.sh
# Purpose: Configure Shell (ZSH) and Core Services
# ==============================================================================

source "$INSTALLER_DIR/scripts/utils.sh"

print_step "Engaging System Identity Protocol..."

# 1. User Shell Setup
print_step ">> Validating Default Shell (ZSH)..."
if [[ "$SHELL" != *"/zsh"* ]]; then
    print_warning "ZSH is not the default shell. Attempting to change..."
    if command -v zsh >/dev/null 2>&1; then
        sudo chsh -s "$(command -v zsh)" "$USER"
        print_success "Shell changed to ZSH. Please log out and back in for changes to take effect."
    else
        print_error "ZSH is not installed. Please run 00-dependencies first."
    fi
else
    print_success "ZSH is already the default shell."
fi

# 2. XDG User Directories
print_step ">> Initializing XDG User Directories..."
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update
    print_success "XDG Directories initialized."
else
    print_warning "xdg-user-dirs not found. Skipping."
fi

# 3. Core Services
print_step ">> Enabling Core System Services..."

# NetworkManager
if systemctl list-unit-files | grep -q "^NetworkManager.service"; then
    sudo systemctl enable --now NetworkManager.service
    print_success "NetworkManager enabled."
fi

# SDDM
if systemctl list-unit-files | grep -q "^sddm.service"; then
    sudo systemctl enable sddm.service
    print_success "SDDM enabled."
else
    print_warning "SDDM service not found. Is it installed?"
fi

print_success "System Identity Module completed."
