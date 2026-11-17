# Release Notes: v4.5.0

**Tag Name:** `v4.5.0`  
**Target Branch:** `main`  
**Title:** `v4.5.0 — CI/CD Automation, Pywal Glassmorphism, Gamemode & Desktop Hardening`

---

## 🌟 Overview

Release **v4.5.0** marks a major evolution in the Pilot HUD dotfiles ecosystem. This release introduces a comprehensive enterprise-grade CI/CD pipeline across GitHub Actions and GitLab, full Pywal dynamic glassmorphism theming across all Rofi menus and Python HUD dialogs, a decoupled SwayNC Game Mode and Night Light engine, and extensive runtime stability hardening across the compositor and shell helpers.

---

## 🚀 Key Highlights & New Features

### 1. 🛠️ Enterprise CI/CD Pipeline & Automated Mirroring
- **GitHub Actions Multi-Tier Pipeline (`.github/workflows/ci.yml`)**:
  - **Static Analysis & Linters**: Automated parallel checks covering Shell (`bash -n` & `ShellCheck`), Lua (`luac -p`), Python (`py_compile` & `ruff`), and JSON schemas (`jq empty`).
  - **Repository Hygiene & Security**: Enforces executable (`+x`) permissions on tracked scripts, validates symlink integrity, runs secret leak detection, and strictly prevents personal `hosts/` profiles from being tracked while keeping `hosts/_template/` available.
  - **Containerized Arch Linux Stow Test**: Spawns an official Arch Linux container to install dependencies and execute dry-run deployments with GNU Stow, catching package collisions before code merges.
- **Automated CD Mirroring (`.github/workflows/mirror.yml`)**:
  - Synchronizes pushes to `main` directly to the secondary GitLab mirror repository using deploy keys with safe-fallback checks.
- **Dedicated Linter Configurations**:
  - Added `ruff.toml` configured specifically for desktop scripts (enforcing `E`, `W`, `F` while handling PyGObject runtime import ordering and line lengths).
  - Added `.shellcheckrc` with dotfiles-aware exclusions for dynamic shell configuration sourcing.
- **Zero-Dependency Local CI Suite (`tests/run-local-ci.sh`)**:
  - 10-point pre-commit test runner allowing instant local validation of syntax, permissions, linting, and stow dry-runs before pushing.

---

### 2. 🎨 Pywal Glassmorphism & UI Palette Synchronization
- **Custom Rofi Dark Glass Template (`core/wal/templates/colors-rofi-dark.rasi`)**:
  - Added an engine template generating dynamic glassmorphism tokens (`bg-base`, `bg-selected`, `accent-color`, `accent-alt`, `border-accent`) directly from wallpaper colors.
- **Universal Rofi Suite Alignment**:
  - Updated all 6 Rofi themes (`launcher.rasi`, `clipboard.rasi`, `runner.rasi`, `selector.rasi`, `window.rasi`, `wallpaper-grid.rasi`) to consume wallpaper-derived background and accent tokens with semi-transparent frosted styling.
- **Dynamic Media Hub (`pilot-hydra.py`)**:
  - Integrated `load_theme()` to read `~/.cache/wal/colors.json` dynamically at launch, generating matching surfaces, hover states, accent borders, and muted text tokens.
- **Clipboard & Power Menu Theming**:
  - Updated `cliphist-rofi.sh` to style ImageMagick thumbnail borders and `imv` previews with Pywal accents.
  - Aligned `core/wlogout/style.css` with `colors-waybar.css` for consistent session menu visuals.

---

### 3. 🎮 SwayNC Gamemode, Night Light & MPRIS Overhaul
- **Dedicated Game Mode Action Tile**:
  - Replaced the 3-stage `powerprofilesctl` toggle with a dedicated Game Mode quick action tile (`󰊖` - controller glyph).
- **Asynchronous Decoupled Execution**:
  - Routed action triggers in `pilot-control.sh` through detached background execution (`nohup ... &`), completely preventing SwayNC UI thread freezes and `libgee` double-free crashes.
- **In-Engine Live Gamemode Reload (`gamemode.sh`)**:
  - Switched compositor reconfiguration to live in-engine Lua evaluation (`hyprctl eval "hl.config({...})"`) instead of full compositor resets, eliminating display flickering and window state drops.
- **Night Light Tile & MPRIS Relocation**:
  - Integrated a dedicated decoupled Hyprsunset Night Light toggle tile in the control center.
  - Repositioned the MPRIS media player directly below the DND toggle as a top hero element with dynamic artwork fallback.
- **Audio Stream Crash Guard**:
  - Disabled `show-per-app` in the volume widget to eliminate upstream `libpulse`/`libgee` stream segfaults.

---

### 4. 🛡️ Desktop Environment & Script Hardening
- **GNOME Keyring Daemon Guard**:
  - Added conflict protection in `hyprland/modules/autostart.lua` against systemd socket activation race conditions.
- **Cold-Boot Visuals Fallback**:
  - Injected fallback color values in `hyprland/modules/visuals.lua` to ensure clean window borders before Pywal generates its first palette.
- **Session Refresh Alias**:
  - Updated the `refresh` alias in `home/.zshrc` to call `swaync-start.sh` for clean notification daemon restarts.
- **Script Bug & Syntax Fixes**:
  - Resolved `SC2168` variable scoping in `wallpaper-effects.sh`.
  - Fixed ImageMagick frame syntax `${wall}[0]` (`SC1087`) in `wallpaper-selector.sh`.
  - Hardened array unsetting in `lib-bind-engine.sh` and parameter shadowing in `rofi-bluetooth.sh`.
  - Refactored exception handling and cleaned PyGObject imports in `pilot-hydra.py`.

---

## 📋 Full Commit Changelog

| Commit | Scope | Description |
| :--- | :--- | :--- |
| `18874ff` | `python, ci` | Add `ruff.toml` configuration and resolve linter warnings in `pilot-hydra.py` |
| `c3d89b5` | `ci, scripts` | Resolve ShellCheck warnings and ignore template files in secret hygiene scanner |
| `b60bb90` | `ci` | Add GitHub Actions workflow, GitLab mirror CD, and local test suite |
| `3186fd7` | `swaync, hypr` | Harden gamemode, integrate nightlight tile, and reposition MPRIS media hero |
| `19c265d` | `theme` | Align interactive window scripts and Rofi themes with Pywal dynamic tokens |
| `c7827f4` | `swaync` | Replace power profile with game mode tile and decouple execution |

---

## 🏷️ Deployment Instructions

### 1. Merge `feature` into `main`
```bash
cd ~/hyprland-dotfiles/main
git merge origin/feature -m "Merge branch 'feature' into main (v4.5.0)"
git push origin main
```

### 2. Create and Push Git Tag
```bash
git tag -a v4.5.0 -m "v4.5.0 — CI/CD Automation, Pywal Glassmorphism, Gamemode & Desktop Hardening"
git push origin v4.5.0
```
