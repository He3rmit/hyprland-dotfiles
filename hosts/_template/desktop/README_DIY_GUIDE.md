# 🛠️ Titanfall Cockpit DIY Guide

Welcome to your new "Donor" setup! This template directory contains everything you need to customize your specific physical machine **without** breaking your Core dotfiles.

The philosophy is simple: **Core handles the standard logic. Host handles the physical hardware.**

---

## 🗺️ The Map: What File Does What?

### 1. `hypr-host.conf` (Hardware Triggers)
This is the heart of your machine. Use this to bind physical hardware keys or launch specific background apps.
*   **Example:** Launching a desktop-specific RGB control software.
*   **Example:** Setting NVIDIA specific environment variables for this machine.

### 2. `monitor.conf` (Screen Layout)
Every screen is different. Do not leave this on `auto` if you want a reliable setup.
*   Run `hyprctl monitors all` in the terminal to find your monitor's name (e.g., `DP-1`, `HDMI-A-1`).
*   Define scaling, refresh rates, and multi-monitor positioning here.

### 3. `user-keybinds.conf` (Workflow Customization)
Your personal flavor goes here. The Core sets standard keys (like `Super+Q` to close), but you set your specific workflow here.
*   **Example:** Bind `Super+O` to open Obsidian.
*   **Example:** Map specific apps to specific workspaces.

### 4. `user-visuals.conf` & `user-windowrules.conf` (Aesthetics & Rules)
If this desktop is older, you can turn off blur and animations in `user-visuals.conf`.
If you want Discord to always open on Workspace 3 on *this* machine only, put it in `user-windowrules.conf`.

### 5. `xdph.conf` & `hyprsunset.conf` (Standalone Rules)
These are complete, independent files. Edit them directly to change screen-sharing rules or night-light temperatures for this specific machine.

### 6. `hypridle-host.conf` & `hyprlock-host.conf` (The Hooks)
These are empty by default! They exist to "hook" into the Core.
*   **Example:** To make this desktop NEVER dim its screen, you could set an aggressively high timeout in `hypridle-host.conf`.

---

## 🎭 Powering the Media Hub (Hydra)

The Hydra Media Hub requires an API key to search for GIFs and Stickers. By default, it looks for this key in a hidden file in your home directory.

### 1. The Secrets File
Create or edit `~/.secrets.sh` and add your Klipy API key:
```bash
export KLIPY_API_KEY="your_actual_key_here"
```

### 2. Obtaining a Key
*   The script uses **Klipy** (api.klipy.co).
*   Search results are limited to the Klipy database.
*   If you don't have a key, the hub will still work for your **Local Vault** and **Emojis**, but the Search tabs will remain empty or print a warning in the terminal.

---

## 🚀 How to Apply This Template to a New Machine
1. Create a new folder for your machine: `mkdir -p ~/dotfiles/hosts/my-new-desktop`
2. Copy these templates over: `cp -r ~/dotfiles/hosts/_template/desktop/* ~/dotfiles/hosts/my-new-desktop/`
3. Edit the files to match your hardware.
4. Point your installer symlink to the new folder!
