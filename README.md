# Titanfall Pilot Desktop (Arch + Hyprland) 🚀

This is a fully declarative, hardware-agnostic ricing project for Arch Linux and Hyprland, heavily inspired by the Titanfall "Pilot HUD" aesthetic. It has evolved into a production-ready, multi-host framework with dynamic display scaling, international layout support, and a cinematic vision engine.

## 🔗 Repository Notice
This is the **PRODUCTION HARDENED** version (v1.2.0). It features a completely modular architecture where your personal settings are kept private and machine-specific.

> [!IMPORTANT]
> **OPERATOR NOTICE**: Keybinds and configurations are heavily at the user's discretion and require personal research. Use this project at your own risk and pace. Enjoy the flight! — **He3rmit**

## 🛠️ Key Features
- **Hardware Trinity**: Intelligent installer that auto-detects and deploys Vulkan/VA-API acceleration for NVIDIA, Intel, and AMD hardware profiles.
- **Display Agnostic**: Built-in scaling wizard and resolution-agnostic optics ensure the HUD looks perfect on everything from 1080p desktops to 4K laptops and Ultrawide displays.
- **International Ready**: Strategic use of **Physical Keycodes** ensures your navigation works natively on QWERTY, AZERTY, QWERTZ, and more without changing a single line of code.
- **Pure Modularity**: Clean separation of `core/` logic and `hosts/` personalization folders.
- **Shell Agnosticism**: Native `shell.local` support for machine-specific aliases and environment variables.

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

### [v1.2.0] — Production Hardened "The Hardened Trinity" (Current)
- **Hardware Trinity**: Implemented auto-detection and driver deployment for various GPU architectures (NVIDIA/Intel/AMD).
- **Cluster Isolation**: Migrated high-workflow workspace clusters to host-specific vaults.
- **Shell Hardening**: Implemented the machine-agnostic `shell.local` profile hook.
- **Labeling**: Added human-readable labels to all physical keycode binds for easier pilot maintenance.

### [v1.1.0] — The Generation 1
- **Pilot Vision**: Implemented the cinematic optics engine with 11 vision modes.
- **Hardware Agnostic**: Fully decoupled all HUD geometry from hardcoded pixel values.
- **Hardening**: Completed the `hosts/` isolation and `.gitignore` security logic.
- **Internationalization**: Switched to physical keycodes for total layout independence.

---

**Pilot, your Titan is standing by. Deploy at your own risk.** 🦾