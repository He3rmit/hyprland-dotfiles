# Titanfall Pilot Desktop (Arch + Hyprland) 🚀

This is a fully declarative, hardware-agnostic ricing project for Arch Linux and Hyprland, heavily inspired by the Titanfall aesthetic. It has evolved into a stable, multi-host framework with dynamic display scaling, international layout support, and a dynamic wallpaper effects engine.

## 🔗 Repository Notice
This is the **Stable Release** version (v3.0.0). It features a completely modular architecture where your personal settings are kept private and machine-specific.

> [!IMPORTANT]
> **OPERATOR NOTICE**: Keybinds and configurations are heavily at the user's discretion and require personal research. Use this project at your own risk and pace. Enjoy the flight! — **He3rmit**

## 🛠️ Key Features
- **Local Host Profiles**: Total separation of `core/` logic and `hosts/` machine configurations. Your monitor, GPU drivers, and local tweaks are kept in a private, Git-ignored directory.
- **Improved Waybar Switcher**: A logic-aware Waybar switcher featuring **Smart Layout Constraints** (prevents Sidebar/Topbar rendering failures) and **Symlink Protection**.
- **Hardware Detection**: Intelligent installer that auto-detects NVIDIA hardware and deploys specific configuration modules.
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

During installation, you will be prompted to create or select a **Host Profile**. This profile stores your machine's specific monitor, scaling, and layout preferences in a private folder that is automatically ignored by Git.

---

## 📖 Documentation
- [MANUAL.md](MANUAL.md) — The Operator's Manual (Keybinds, Visual Effects, Migration Guide).
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

### [v3.0.0] — Lua Configuration Migration & Hyprland v0.55+ Compliance (Current)
- **Native Lua Architecture**: Upgraded the entire core repository and Host Vaults from the legacy `.conf` format to Hyprland's native, high-performance `.lua` configuration parser.
- **Automated Migration Tool**: Developed `installer/scripts/migrate-to-lua.sh` utilizing advanced Perl-based post-processors to flawlessly translate your legacy user configurations, device blocks, and environment variables into perfect Lua syntax.
- **App Launcher Intelligence**: Rewrote the Rofi Tactical Briefing backend (`lib-bind-engine.sh`) to natively parse Lua. It perfectly preserves your keybind cluster metadata and custom workspace layouts for immediate visual feedback.
- **Installer Improvements**: Upgraded the Deployment Engine to dynamically generate `.lua` state files (keyboard/touchpad logic) while explicitly shielding standalone C++ utilities (Hypridle/Hyprlock/Hyprsunset) from breaking.

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