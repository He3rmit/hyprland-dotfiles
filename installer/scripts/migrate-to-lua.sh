#!/bin/bash
# ==============================================================================
# SCRIPT: migrate-to-lua.sh
# PURPOSE: Automates the transition from legacy .conf files to Hyprland 0.55+ .lua
# ==============================================================================

# Get directory of this script to source utils
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$SCRIPT_DIR/utils.sh"

cd "$DOTFILES_DIR" || exit 1

print_step "Installing hyprlang2lua..."
aur_install "hyprlang2lua"

# List of files to convert
# Excludes tools that haven't moved to Lua (hypridle, hyprlock, hyprsunset, kitty)
FILES=(
    "hyprland/hyprland.conf"
    "hyprland/user-keybinds.conf"
)

# Add all module confs except generated ones
while read -r file; do
    FILES+=("$file")
done < <(find hyprland/modules/ -name "*.conf" ! -name "keyboard.conf" ! -name "colors.conf" 2>/dev/null)

# Add all host confs (templates and specific machines)
while read -r file; do
    FILES+=("$file")
done < <(find hosts/ -name "hypr-host.conf" -o -name "monitor.conf" -o -name "nvidia.conf" -o -name "user-keybinds.conf" -o -name "user-windowrules.conf" -o -name "user-visuals.conf" 2>/dev/null)

print_step "Converting configs to Lua..."

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        lua_file="${file%.conf}.lua"
        print_step "  Translating $file -> $lua_file"
        
        # hyprlang2lua takes input file as first arg and outputs to stdout
        hyprlang2lua "$file" > "$lua_file" 2>/dev/null
        
        # If hyprlang2lua failed (or generated empty output), let the user know
        if [ ! -s "$lua_file" ]; then
            print_warning "    Warning: Translation of $file failed or output was empty."
            rm -f "$lua_file"
            continue
        fi
        
        # Fix sourcing statements inside the translated Lua files
        # Convert `source = ~/.config/hypr/path/to/file.conf` -> `require("path.to.file")`
        # Using Perl because it handles regex group replacements cleanly
        perl -pi -e 's|hl\.config\(\{\s*source\s*=\s*"~/\.config/hypr/(.*?)\.conf"\s*\}\)|require("\1")|g' "$lua_file"
        perl -pi -e 's|source\s*=\s*"~/\.config/hypr/(.*?)\.conf"|require("\1")|g' "$lua_file"
        
        # --- LUA COMPATIBILITY POST-PROCESSING CORRECTIONS ---
        
        # 1. Promote chunk-scoped local apps and mainMod assignments to global variables
        perl -pi -e 's/^local\s+(mainMod|terminal|fileManager|menu|runner)\s*=\s*/\1 = /g' "$lua_file"
        
        # 2. Fix hyphenated touchpad setting 'tap-to-click' to underscore 'tap_to_click'
        perl -pi -e 's/\["tap-to-click"\]/tap_to_click/g' "$lua_file"
        
        # 3. Fix active_border gradient syntax from string concatenation to Lua tables
        perl -pi -e 's/active_border\s*=\s*(\w+)\s*\.\.\s*" "\s*\.\.\s*(\w+)\s*\.\.\s*"\s*(\d+)deg"/active_border = { colors = { \1, \2 }, angle = \3 }/g' "$lua_file"
        
        # 4. Remove unsupported 'rounding = ...' properties from inside hl.workspace_rule blocks
        perl -0777 -pi -e 's/(hl\.workspace_rule\(\{[\s\S]*?)\n\s*rounding\s*=\s*\d+,?/\1/g' "$lua_file"
        
        # 5. Fix hl.dsp.exec_cmd literal string variable references (e.g. "$terminal" -> terminal)
        perl -pi -e 's/hl\.dsp\.exec_cmd\("\$(\w+)"\)/hl.dsp.exec_cmd(\1)/g' "$lua_file"
        
        # 6. Convert invalid hl.config device blocks to the new hl.device API format
        perl -0777 -pi -e 's/hl\.config\(\{\s*device\s*=\s*\{\s*name\s*=\s*(".*?"|\w+),\s*enabled\s*=\s*(true|false)\s*\}\s*\}\)/hl.device({\n    name = \1,\n    enabled = \2\n})/gs' "$lua_file"

        # Backup the legacy config
        mv "$file" "$file.bak"
    fi
done

print_success "Translation complete! Legacy .conf files have been backed up as .bak"
