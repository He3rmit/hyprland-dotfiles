# Titanfall Pilot Desktop (Arch + Hyprland) 🚀

This is a fully declarative, hardware-agnostic ricing project for Arch Linux and Hyprland, heavily inspired by the Titanfall "Pilot HUD" aesthetic. It has evolved into a production-ready, multi-host framework with dynamic display scaling, international layout support, and a cinematic vision engine.

## 🔗 Repository Notice
This is the **PRODUCTION HARDENED** version (v1.2.0). It features a completely modular architecture where your personal settings are kept private and machine-specific.

> [!IMPORTANT]
> **OPERATOR NOTICE**: Keybinds and configurations are heavily at the user's discretion and require personal research. Use this project at your own risk and pace. Enjoy the flight! — **He3rmit**

## 🛠️ Key Features
- **The Hardware Vault**: Total separation of `core/` logic and `hosts/` machine configurations. Your monitor, GPU drivers, and local tweaks are kept in a private, Git-ignored vault.
- **Generation 2 Switcher Engine**: A logic-aware Waybar switcher featuring the **Axis-Lock** protocol (prevents Sidebar/Topbar rendering failures) and **Link-Break** source protection.
- **Hardware Trinity**: Intelligent installer that auto-detects NVIDIA hardware and deploys vault-aware configuration modules.
- **Resolution-Agnostic Optics**: Leveraging the Host-Vault scaling protocol, the HUD renders perfectly across 1080p, 1440p, 4K, and Ultrawide displays without code changes.
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
- [MANUAL.md](MANUAL.md) — The Operator's Manual (Keybinds, Pilot Vision, Migration Guide).
- [LICENSE](LICENSE) — Licensed under GNU GPL v3.0.

---

## 📂 Repository Structure

```
dotfiles/
├── core/              # SHARED LOGIC (The "Chassis")
├── hosts/             # PERSONALIZATION (The "Neuro-Link")
│   ├── _template/     # Starter kits (Laptop / Desktop)
│   └── [your-host]/   # Your private configs (PROTECTED & IGNORED)
├── hyprland/          # MODULAR WM CONFIG
│   ├── modules/       # Keybinds, Visuals, Autostart, Pilot-Optics
│   └── hyprland.conf  # Main entry point
├── home/              # SHELL ENVIRONMENT (.zshrc, .bashrc)
└── installer/         # TUI DEPLOYMENT ENGINE
```

---

### [v1.3.0] — Total Architectural Re-Alignment (Current)
- **Generation 2 Engine**: Refactored `waybar-switcher.sh` with **Axis-Lock** intelligence and **Link-Break** source protection.
- **Vault Centralization**: Migrated all machine-specific identity (`monitor.conf`, `nvidia.conf`, `touchpad.conf`) into isolated host vaults.
- **Pilot-Control Suite**: Implemented the `pilot-control` CLI and GUI for tactile system management.
- **Discovery Engine**: Refactored the Wallpaper Selector to support dual-library discovery for personal assets.

### [v1.2.0] — Production Hardened "The Hardened Trinity"
- **Hardware Trinity**: Implemented auto-detection and driver deployment for various GPU architectures (NVIDIA/Intel/AMD).
- **Cluster Isolation**: Migrated high-workflow workspace clusters to host-specific vaults.
- **Shell Hardening**: Implemented the machine-agnostic `shell.local` profile hook.

### [v1.1.0] — The Generation 1
- **Pilot Vision**: Implemented the cinematic optics engine with 11 vision modes.
- **Hardware Agnostic**: Fully decoupled all HUD geometry from hardcoded pixel values.
- **Hardening**: Completed the `hosts/` isolation and `.gitignore` security logic.
- **Internationalization**: Switched to physical keycodes for total layout independence.

---

**Pilot, your Titan is standing by. Deploy at your own risk.** 🦾