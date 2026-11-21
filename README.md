# Titanfall Pilot Desktop (Arch + Hyprland) 🚀

This is a fully declarative, hardware-agnostic ricing project for Arch Linux and Hyprland, heavily inspired by the Titanfall aesthetic. It has evolved into a stable, multi-host framework with dynamic display scaling, international layout support, and a dynamic wallpaper effects engine.

## 🔗 Repository Notice
This is the **Stable Release** version (v4.5.1). It features a completely modular architecture where your personal settings are kept private and machine-specific.

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

## 🔄 Upgrading to v4.x (Native Lua & Modular Architecture)

If you are an existing user upgrading from a pre-v4.0 release:

> [!NOTE]
> The deployment engine features automated legacy-to-Lua compilation for existing host configurations and host-first linking for `hypridle` and `hyprlock`. Running `./installer/install.sh` will automatically migrate your setup.

Run these steps in order:
```bash
# 1. Pull the latest updates
git pull

# 2. Re-run the deployment engine to sync symlinks, auto-bridge legacy configs, and refresh modules
./installer/install.sh
```

---

## 📖 Documentation
- [MANUAL.md](MANUAL.md) — The Operator's Manual (Keybinds, Visual Effects, Deployment Architecture).
- [DIY_GUIDE.md](DIY_GUIDE.md) — Machine Customization & Host Vault Setup Guide.
- [CHANGELOG.md](CHANGELOG.md) — Comprehensive version history and release logs.
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

## 🚀 Latest Updates (v4.5.1)

- **Gamemode & Idle Hardening**: Cleanly terminates and relaunches `hypridle` daemon during Game Mode transitions to eliminate screen-locking during gameplay.
- **Universal Keyboard Backlight**: Switched `hypridle.conf` to a driver-agnostic wildcard selector (`*::kbd_backlight`) for automatic laptop keyboard illumination management across vendor ACPI drivers.
- **13-Point Local CI Suite**: Comprehensive local testing (`tests/run-local-ci.sh`) covering ShellCheck, luac, ruff, JSONC, CSS/RASI linting, keybinding target integrity, script smoke tests, and Stow template dry-runs.
- **Automated CD Release Packaging**: Integrated release asset creation, SHA256 checksums, and automated changelog publishing directly into GitHub Actions.
- **SwayNC & Bluetooth Hardening**: Restored per-app audio controls and hardened Bluetooth reconnect handling following system resume.

> [!TIP]
> For full historical changes dating back to v1.1.0, see **[CHANGELOG.md](CHANGELOG.md)** or browse **[GitHub Releases](https://github.com/He3rmit/hyprland-dotfiles/releases)**.

---

**Enjoy your new setup!** 🚀
