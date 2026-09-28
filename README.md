# Titanfall Pilot Desktop (Arch + Hyprland) 🚀

This is a fully declarative, hardware-agnostic ricing project for Arch Linux and Hyprland, heavily inspired by the Titanfall aesthetic. It has evolved into a stable, multi-host framework with dynamic display scaling, international layout support, and a dynamic wallpaper effects engine.

## 🔗 Repository Notice
This is the **Stable Release** version (v4.0.0). It features a completely modular architecture where your personal settings are kept private and machine-specific.

> [!IMPORTANT]
> **OPERATOR NOTICE**: Keybinds and configurations are heavily at the user's discretion and require personal research. Use this project at your own risk and pace. Enjoy the flight! — **He3rmit**

## 🛠️ Key Features
- **Local Host Profiles**: Total separation of `core/` logic and `hosts/` machine configurations. Your monitor, GPU drivers, and local tweaks are kept in a private, Git-ignored directory.
- **Decoupled Media Architecture**: Video wallpapers and SDDM cinematics are hosted via GitHub Releases and downloaded on demand via `fetch-media.sh`. Keeps the Git repository under ~75 MB for fast cloning.
- **Hardware Auto-Alignment**: Dynamic backlight auto-detection for SwayNC (`amdgpu_bl*` vs `intel_backlight`) and automatic touchpad hardware identification.
- **Hydra Media Hub**: Native GTK3 Python hub for searching and deploying animated GIFs (Giphy/Klipy), stickers, and emojis (`Super + Shift + E`).
- **Improved Waybar Switcher**: A logic-aware Waybar switcher featuring **Smart Layout Constraints** (prevents Sidebar/Topbar rendering failures) and **Symlink Protection**.
- **Hardware Detection**: Intelligent installer that auto-detects NVIDIA/Intel/AMD hardware and deploys specific acceleration modules.
- **Resolution-Agnostic Optics**: Leveraging the Host-Vault scaling protocol, the UI renders perfectly across 1080p, 1440p, 4K, and Ultrawide displays without code changes.
- **Dual-Library Discovery**: The Wallpaper Engine merges your Git-tracked library with a private local wallpaper directory (`~/Pictures/Wallpapers/`) for a seamless, private collection.
- **International Ready**: Strategic use of **Physical Keycodes** ensures your navigation works natively on QWERTY, AZERTY, QWERTZ, and more.

---

## ⚡ Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/He3rmit/hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Run the interactive deployment engine
./installer/install.sh
```

During installation, you will be prompted to create or select a **Host Profile** and optionally download the **Titanfall Media Pack** (~300MB live wallpapers and SDDM cinematics).

---

## 🔄 Upgrading from v2.x to v3.x

If you are an existing user upgrading from the legacy `.conf` configuration era to the new native `.lua` structure:

> [!WARNING]
> Running `git pull` without migrating your local host overrides will temporarily break your keybinds and visual rules. You must convert your files to Lua format.

Run these steps in order:
```bash
# 1. Pull the latest updates
git pull

# 2. Translate your local host overrides from .conf to .lua
./installer/scripts/migrate-to-lua.sh

# 3. Re-run the deployment engine to sync symlinks and dependencies
./installer/install.sh
```

---

## 📖 Documentation
- [MANUAL.md](MANUAL.md) — The Operator's Manual (Keybinds, Visual Effects, Deployment Architecture).
- [DIY_GUIDE.md](DIY_GUIDE.md) — Machine Customization & Host Vault Setup Guide.
- [LICENSE](LICENSE) — Licensed under GNU GPL v3.0.

---

## 📂 Repository Structure

```
dotfiles/
├── core/              # SHARED LOGIC (Shared Configs)
├── hosts/             # PERSONALIZATION (Local Profiles)
│   ├── _template/     # Starter kits (Laptop / Desktop)
│   └── [your-host]/   # Your private configs (PROTECTED & IGNORED)
├── hyprland/          # MODULAR WM CONFIG
│   ├── modules/       # Keybinds, Visuals, Autostart, Wallpaper Effects
│   └── hyprland.lua  # Main entry point
├── home/              # SHELL ENVIRONMENT (.zshrc, .bashrc)
└── installer/         # DEPLOYMENT ENGINE
```

---

### [v4.0.0] — Full Lua Runtime Compliance, Bilingual Script Engine & Host Auto-Bridging (Current)
- **Complete Hyprland Lua Modernization**: Finalized migration of the core window manager configuration to modern Hyprland Lua syntax (`hl.*`, `hl.dsp.*`), ensuring native compatibility with Hyprland 0.55+.
- **Bilingual Control Script Engine**: Updated helper scripts (`mirror-hotplug.sh`, `wallpaper-selector.sh`, `waybar-switcher.sh`, `wlogout`, and `hypridle`) to support bilingual execution—executing Lua dispatchers (`hl.dsp.*`) first with seamless fallbacks to legacy dispatchers, eliminating interpreter syntax errors and accidental session termination.
- **Installer Host Auto-Bridging**: Upgraded `01-stow-configs.sh` to automatically detect legacy `.conf` user overrides (`user-keybinds.conf`, `user-windowrules.conf`, `user-visuals.conf`) and compile them to `.lua` via `hyprlang2lua` during deployment.
- **Desktop & Laptop Profile Template Parity**: Added missing `user-visuals.lua` and `user-windowrules.lua` templates for desktop environments and cleaned up legacy migration artifacts across host templates.
- **Waybar Switcher Race Condition Hardening**: Replaced naive process termination in `waybar-switcher.sh` with an explicit PID polling wait loop to ensure clean UI lifecycle reloads.
- **Dynamic Pywal Dual-Export**: Updated `wallpaper-selector.sh` to populate both `colors.lua` and `colors.conf` upon color scheme generation, followed by live `hyprctl reload`.
- **Interchangeable Hypridle & Hyprlock Architecture**: Elevated `hypridle.conf` and `hyprlock.conf` to first-class interchangeable host modules (Host First, Default Fallback). Allows hosts (e.g. desktops vs. laptops) to fully customize or omit listeners without rigid variable constraints, while maintaining seamless fallback to core defaults.

### [v3.3.0] — Decoupled Media Assets, Hardware Alignment & Bloat Pruning
- **Decoupled Heavy Media Assets**: Decoupled all `.mp4` video wallpapers and SDDM login cinematics from Git into GitHub Release assets (`fetch-media.sh`). Reduced Git clone payload from >500 MB down to **~75 MB**.
- **Hardware Auto-Alignment**: Integrated dynamic backlight detection in `swaync-start.sh` (supporting both `amdgpu_bl*` and `intel_backlight`) and dynamic touchpad hardware detection in the installer.
- **Hypridle & Hyprlock Resilience**: Refactored `hypridle` with an overrideable `$TIMEOUT_*` variable architecture to eliminate duplicate listener conflicts, and enabled `immediate_render = true` in `hyprlock` to eliminate wake-from-suspend black screens.
- **Bloat Pruning & Image Optimization**: Converted oversized 29 MB raw PNG into an optimized 4K JPG (1.5 MB), purged 500+ lines of unreferenced prototype shell scripts, and streamlined dependencies in `00-dependencies.sh`.
- **Unified Power Protocol**: Consolidated power cycling logic across Waybar and SwayNC into a single source of truth (`power_cycle.sh`).
- **Resilient Environment**: Added dynamic `$EDITOR` fallback in `.zshrc` (`nvim` ➔ `micro` ➔ `nano` ➔ `vi`) and `timeout 1s` safety buffer on `upower` queries in Waybar.

### [v3.1.0] — Security Hardening & Hydra Media Hub
- **Multi-API Media Engine**: Expanded the media selector (`pilot-hydra.py`) to support **Giphy** alongside **Klipy**, automatically selecting Giphy if configured.
- **Unified GTK Media Hub**: Consolidated animated GIFs, Klipy stickers, local stickers, and dynamic emojis into the native GTK3 `pilot-hydra.py` application (`Super + Shift + E`).
- **Configuration Cleanups**: Replaced legacy `.conf` commented templates in host vaults with valid, native Lua table comments.
- **Setup Guide Relocation**: Consolidated individual setup documents into a single, clean, jargon-free `DIY_GUIDE.md` in the repository root.

### [v3.0.0] — Lua Configuration Migration & Hyprland v0.55+ Compliance
- **Native Lua Architecture**: Upgraded the entire core repository and Host Vaults from the legacy `.conf` format to Hyprland's native, high-performance `.lua` configuration parser.
- **Automated Migration Tool**: Developed `installer/scripts/migrate-to-lua.sh` to translate legacy user configurations, device blocks, and environment variables into perfect Lua syntax.
- **App Launcher Keybinds**: Rewrote the Rofi keybind helper backend (`lib-bind-engine.sh`) to natively parse Lua, preserving custom layout metadata and shortcuts.
- **Installer Improvements**: Upgraded the installer to dynamically generate `.lua` state files (keyboard/touchpad logic) while explicitly shielding standalone utilities (Hypridle/Hyprlock/Hyprsunset) from breaking.

### [v2.2.0] — Dynamic Wallpaper Engine & Link-Break Hardening
- **Wallpaper Auto-Pause**: Added dynamic wallpaper auto-pause (`-p` / `--auto-pause`) to `mpvpaper` live wallpaper rendering. Automatically halts decoding when hidden under windows, slashing CPU overhead to 0% and massively extending battery life while working.
- **SwayNC Link-Break Protection**: Hardened `waybar-switcher.sh` to automatically detect and break GNU Stow symlinks for SwayNC configuration files upon position synchronizations. Blocks local transient coordinate settings from polluting the Git tracking tree.
- **Keybind Sourcing Priority**: Purged keybind double-sourcing from modular configurations, ensuring that host-specific user overrides are sourced strictly at the end of the Hyprland lifecycle to eradicate double-triggering.
- **Full Proton Compatibility**: Deployed dynamic hardware drivers for hybrid architectures (`lib32-vulkan-intel`, `lib32-vulkan-radeon`) as core installer dependencies for Steam/Proton compatibility.
- **Troubleshooting Tools**: Included Wayland Event Viewer (`wev`) as a default setup helper tool for easy keybind tracing, corrected audio lockups in `mic.sh` with a Pipewire settling delay, and removed deprecated VFR flags to safeguard display synchronization.

### [v1.4.0] — The Pure GTK Pivot & Architectural Integrity
- **GTK Native Shift**: Completely purged KDE/Qt dependencies (Dolphin, Ark, KIO) in favor of lightweight GTK native equivalents (Thunar, File-Roller, Tumbler).
- **Polkit Isolation Fix**: Resolved systemd race conditions by directly launching the authentication agent natively as a child process of Hyprland.
- **User Overrides Integrity**: Fixed critical flaw in master config to properly source and prioritize host-specific user overrides (`user-keybinds.lua`, `user-windowrules.lua`, `user-visuals.lua`).
- **System Identity Engine**: Added `02-system-identity.sh` module to the installer for better shell and environment bootstrapping.

### [v1.3.0] — Total Architectural Re-Alignment
- **Improved Switcher Engine**: Refactored `waybar-switcher.sh` with **Axis-Lock** intelligence and **Link-Break** source protection.
- **Vault Centralization**: Migrated all machine-specific identity (`monitor.lua`, `nvidia.lua`, `touchpad.lua`) into isolated host vaults.
- **Desktop Management Tools**: Implemented the `pilot-control` CLI and GUI for system management.
- **Discovery Engine**: Refactored the Wallpaper Selector to support dual-library discovery for personal assets.

### [v1.2.0] — Production Hardened "Hardware Detection"
- **Hardware Detection**: Implemented auto-detection and driver deployment for various GPU architectures (NVIDIA/Intel/AMD).
- **Workspace Isolation**: Migrated high-workflow workspace clusters to host-specific vaults.
- **Shell Hardening**: Implemented the machine-agnostic `shell.local` profile hook.

### [v1.1.0] — Initial Release
- **Visual Effects**: Implemented the cinematic optics engine with 11 vision modes.
- **Hardware Agnostic**: Fully decoupled all UI geometry from hardcoded pixel values.
- **Hardening**: Completed the `hosts/` isolation and `.gitignore` security logic.
- **Internationalization**: Switched to physical keycodes for total layout independence.

---

**Enjoy your new setup!** 🚀