# 🛠️ Host Configuration & DIY Setup Guide

Welcome to the host configuration guide. The repository is structured to allow you to customize your physical machine without modifying the shared core dotfiles.

The configuration architecture is divided into two parts:
1. **Core (`hyprland/`)**: Handles standard logic, default aesthetics, and core window management rules.
2. **Host (`hosts/`)**: Handles machine-specific hardware triggers, overrides, and personal workflows.

---

## 🗺️ File Reference Guide

### 1. `hypr-host.lua` (Hardware Keybinds)
Use this file to bind physical hardware keys (like `Fn` keys or dedicated media keys) to system scripts.
*   **Example:** Mapping a dedicated microphone mute button or laptop-specific brightness controls.

### 2. `monitor.lua` (Display Configuration)
Every screen is different. It is recommended not to leave this on `auto` if you want a reliable setup.
*   Run `hyprctl monitors all` in the terminal to find your monitor's name (e.g., `eDP-1`, `DP-1`).
*   Define scaling, refresh rates, and multi-monitor positioning here.

### 3. `user-keybinds.lua` (Workflow Customization)
Your personal keybindings go here. The core sets standard binds (like `Super+Q` to close), but you define your specific workflow here.
*   **Example:** Bind `Super+O` to open Obsidian.
*   **Example:** Map specific apps to specific workspaces.

### 4. `user-visuals.lua` & `user-windowrules.lua` (Aesthetics & Rules)
*   **Performance:** If you are running on a low-end machine or battery, turn off blur and animations in `user-visuals.lua`.
*   **Window Rules:** If you want an app (like Discord) to always open on Workspace 3 on this specific machine, define it in `user-windowrules.lua`.

### 5. `xdph.conf` & `hyprsunset.conf` (Standalone Rules)
These are complete, independent files. Edit them directly in your host folder to change screen-sharing rules or night-light temperature behaviors for this specific machine.

### 6. `hypridle-host.conf` & `hyprlock-host.conf` (Overrides)
These are empty by default! They exist to override or hook into the core configuration.
*   **Example:** To make a laptop screen dim after 1 minute (while keeping a desktop set to 10 minutes), add `timeout = 60` to the laptop's `hypridle-host.conf`.

---

## 🎭 Media Search API (Klipy)

The media and GIF selector requires an API key to search for external GIFs and Stickers. By default, it searches for this key in a hidden file in your home directory.

### 1. The Secrets File
Create or edit `~/.secrets.sh` and add your Klipy API key:
```bash
export KLIPY_API_KEY="your_actual_key_here"
```

### 2. Obtaining a Key
*   The script uses **Klipy** (api.klipy.co).
*   Search results are limited to the Klipy database.
*   If you don't have a key, the media selector will still work for your **Local Assets** and **Emojis**, but the Search tabs will remain empty or print a warning in the terminal.

---

## 🚀 How to Create a New Host Profile
1. Create a new folder for your machine in the hosts directory:
   `mkdir -p ~/hyprland-dotfiles/hosts/my-new-machine`
2. Copy the templates over (choose desktop or laptop):
   `cp -r ~/hyprland-dotfiles/hosts/_template/laptop/* ~/hyprland-dotfiles/hosts/my-new-machine/`
3. Edit the `.lua` and `.conf` files to match your hardware.
4. Point your installer symlink to the new folder and reload Hyprland.
