#!/usr/bin/env bash
# ==============================================================================
# TITANFALL PILOT HUD — MEDIA ASSET MANAGER
# Purpose: Manages live wallpapers (.mp4) and SDDM cinematics decoupled from git.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$SCRIPT_DIR/utils.sh"

REPO="He3rmit/hyprland-dotfiles"
RELEASE_TAG="latest"
ASSET_NAME="titanfall-media-pack.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"
OUTPUT_ARCHIVE="$DOTFILES_DIR/$ASSET_NAME"

# Check if media files are installed
check_media() {
    local missing=0
    if [ ! -f "$DOTFILES_DIR/sddm/astronaut/Movies/titanfall_intro_cinematic.mp4" ]; then
        missing=$((missing + 1))
    fi
    local live_count
    live_count=$(find "$DOTFILES_DIR/core/wallpapers/library" -name "*-Live.mp4" 2>/dev/null | wc -l)
    if [ "$live_count" -lt 3 ]; then
        missing=$((missing + 1))
    fi
    return $missing
}

# Package local media into a release asset archive
package_media() {
    print_step ">> Packaging media assets into $ASSET_NAME..."
    cd "$DOTFILES_DIR" || exit 1
    
    local files_to_pack=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && files_to_pack+=("$file")
    done < <(find core/wallpapers/library -name "*.mp4" 2>/dev/null)

    while IFS= read -r file; do
        [[ -n "$file" ]] && files_to_pack+=("$file")
    done < <(find sddm/astronaut/Movies -name "*.mp4" 2>/dev/null)

    if [ ${#files_to_pack[@]} -eq 0 ]; then
        print_error "No .mp4 media files found to package!"
        exit 1
    fi

    echo "Packaging ${#files_to_pack[@]} video files..."
    tar -czf "$OUTPUT_ARCHIVE" "${files_to_pack[@]}"
    
    local size
    size=$(du -h "$OUTPUT_ARCHIVE" | awk '{print $1}')
    print_success "Archive created: $OUTPUT_ARCHIVE ($size)"
    echo "💡 Upload this file to your GitHub Release under: https://github.com/${REPO}/releases"
}

# Download and extract media assets
download_media() {
    if check_media; then
        print_success "Media pack is already installed."
        return 0
    fi

    print_step ">> Downloading Titanfall Media Pack from GitHub..."
    local temp_tar
    temp_tar=$(mktemp /tmp/titanfall-media-XXXXXX.tar.gz)

    if command -v curl &>/dev/null; then
        if ! curl -f -L --progress-bar "$DOWNLOAD_URL" -o "$temp_tar"; then
            print_error "Failed to download media pack from $DOWNLOAD_URL"
            rm -f "$temp_tar"
            return 1
        fi
    elif command -v wget &>/dev/null; then
        if ! wget --show-progress -qO "$temp_tar" "$DOWNLOAD_URL"; then
            print_error "Failed to download media pack from $DOWNLOAD_URL"
            rm -f "$temp_tar"
            return 1
        fi
    else
        print_error "Neither curl nor wget is available!"
        rm -f "$temp_tar"
        return 1
    fi

    print_step ">> Extracting media assets into dotfiles..."
    tar -xzf "$temp_tar" -C "$DOTFILES_DIR"
    rm -f "$temp_tar"

    print_success "Titanfall Media Pack installed successfully."
}

case "$1" in
    --package) package_media ;;
    --download) download_media ;;
    --check)
        if check_media; then
            echo "installed"
        else
            echo "missing"
        fi
        ;;
    *)
        echo "Usage: $0 {--download|--package|--check}"
        exit 1
        ;;
esac
