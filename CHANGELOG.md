# Changelog

All notable changes to the Titanfall Pilot HUD project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v4.5.1] - 2026-11-21

### Added
- **Expanded 13-Point CI/CD Pipeline & Local Test Suite**:
  - Added `tests/validate-jsonc.py` verifying JSON/JSONC configuration files against comments and trailing commas.
  - Added `tests/validate-styles.py` verifying CSS and Rofi RASI brace/bracket structural integrity.
  - Added `tests/validate-keybind-targets.py` ensuring all 28 referenced executable script targets exist.
  - Added `tests/validate-hypr-configs.py` validating block syntax across Hypridle and Hyprlock configurations.
  - Added `tests/test-scripts-smoke.sh` executing functional CLI contract checks (`gamemode.sh`, `pilot-control`, `lib-bind-engine`, `mic.sh`).
  - Added `tests/test-stow-templates.sh` executing mock GNU Stow deployments across laptop and desktop templates.
  - Added automated release packaging in `.github/workflows/ci.yml` creating release tarballs and SHA256 checksums.
  - Added automated release note extraction in `.github/workflows/ci.yml` supporting both `RELEASE_NOTES_${TAG_NAME}.md` and `CHANGELOG.md`.

### Fixed
- **Gamemode Hyprlock Idle Bug**: Replaced process freezing (`killall -STOP/-CONT hypridle`) with clean process termination on engage and detached background spawn `(nohup hypridle </dev/null >/dev/null 2>&1 &)` on disengage in `hyprland/scripts/gamemode.sh`, preventing delayed idle timeouts from locking the screen during gaming.
- **Universal Laptop Keyboard Backlight**: Switched keyboard backlight listener in `hypridle.conf` (core and templates) to use wildcard `*::kbd_backlight`, dynamically discovering vendor ACPI drivers (`msiacpi`, `asus`, `dell`, etc.) without failing silently.
- **SwayNC Per-App Audio Dropdown**: Restored per-app audio stream sliders (`"show-per-app": true`) in `core/swaync/config.json`.
- **Bluetooth Handle Reconnection**: Hardened device reconnect logic after system idle and suspend.
- **Audio Script Safety (`mic.sh`)**: Reordered argument validation in `hyprland/scripts/mic.sh` to validate commands (`up`, `down`, `toggle`) prior to probing WirePlumber, enabling safe diagnostic execution on minimal environments.

---

## [v4.5.0] - 2026-11-17

### Added
- **Enterprise CI/CD & Automated CD Mirroring**: Added a multi-tier GitHub Actions workflow (`.github/workflows/ci.yml`) covering static analysis (`ShellCheck`, `luac`, `ruff`, `jq`), security and repository hygiene (permissions, symlinks, host profile privacy, secret scanner), containerized Arch Linux stow dry-runs, and automated CD mirroring to GitLab (`.github/workflows/mirror.yml`). Added a zero-dependency local test runner (`tests/run-local-ci.sh`) and standardized `ruff.toml` and `.shellcheckrc`.
- **Pywal Glassmorphism & UI Color Synchronization**: Created dynamic dark glass Rofi template (`core/wal/templates/colors-rofi-dark.rasi`), aligned all 6 Rofi themes with wallpaper-derived palette tokens, integrated dynamic Pywal theme loading in the Python Media Hub (`pilot-hydra.py`), and unified thumbnail/preview styling in `cliphist-rofi.sh` and `wlogout`.
- **SwayNC Gamemode, Night Light & MPRIS Overhaul**: Replaced power profiles with a dedicated Game Mode quick action tile (`󰊖`) running live in-engine Lua reconfiguration (`hyprctl eval`) to eliminate window drops; decoupled script execution via background jobs to prevent UI thread freezes; added Night Light action tile; relocated MPRIS media hero below DND; and guarded against audio stream segfaults.
- **Desktop Stability & Script Hardening**: Added GNOME Keyring Daemon startup conflict guards, cold-boot Pywal color fallbacks in `visuals.lua`, updated `refresh` alias to `swaync-start.sh`, and resolved ShellCheck / exception handling issues across control scripts.

---

## [v4.4.0] - 2026-11-04

### Added
- **Dual-Themed SwayNC Pilot HUD**: Redesigned `core/swaync/style.css` and introduced 5 Waybar-matched theme sheets (`core/swaync/themes/*.css`) that inherit Pywal dynamic colors (`colors-waybar.css`) alongside active Waybar style syncing via `sync_swaync_theme` in `waybar-switcher.sh`.
- **Auto-Expanding Sizing & Live Quick Toggles**: Switched SwayNC `control-center-height` to auto-expanding (`-1`) with `10px` outer margins, refined sliders/MPRIS/per-app volume/notification cards, and wired live hardware state queries (`wifi-status`, `bt-status`, `volume.sh status`) into Wi-Fi, Bluetooth, and Audio quick toggles.
- **SwayNC Orientation Alignment**: Upgraded `waybar-switcher.sh` (`--sync-swaync`) with a JSONC parser covering multi-line `modules-*` and `group/*` nesting so SwayNC dynamically tracks Waybar's edge and notification block placement; delegated `01-stow-configs.sh` alignment to `--sync-swaync` and updated stow/uninstall handling for `theme.css`.
- **Waybar Layouts, Capsules & Contextual Sidebar Positioning**: Modernized all 5 Waybar layouts and themes (`1-Titan-Glass` through `5-Glass-Pill`) with `hyprland/window` telemetry, stitched `#hardware` and `#comms` capsules, calibrated baselines, and contextual `"Left\nRight"` sidebar edge selection with normalized case handling and margin flipping.
- **Runtime Performance & Cliphist Thumbnails**: Eliminated blocking subprocesses, synchronous notifications, and redundant subshell forks across control scripts while generating top-item thumbnails synchronously in `cliphist-rofi.sh` for immediate preview.

---

## [v4.3.0] - 2026-10-24

### Added
- **Hyprland 0.57+ Upstream Alignment**: Hardened configuration and runtime scripts against Hyprland 0.57 changes—purged deprecated `hyprctl keyword` calls across `gamemode.sh` and `mirror-hotplug.sh` in favor of native `hyprctl eval ("hl.config({...})")` and `hl.monitor({...})`.
- **Legacy `.conf` Purge**: Removed the obsolete `hyprland/hyprland.conf` transition stub, pruned dual-exported `colors.conf`, and sanitized `.gitignore` and `.stow-local-ignore` for pure Lua runtime operation.
- **Hyprlock HUD Layout Redesign**: Relocated the lockscreen keyboard layout indicator (`$LAYOUT`) to the bottom-right corner (`-30, 30`) with a dedicated keyboard glyph (`󰌌  $LAYOUT`), resolving visual overlap across the password input field.
- **Hyprland 0.57 Feature Stubs**: Integrated template stubs and documentation for new 0.57 capabilities, including window wobble (`decoration.wobble`), inner edge glow (`decoration.glow`), proportional blur (`decoration.blur.proportional`), cursor warping (`cursor.warp_on_monitor_change`), and the native config reload dispatcher (`hl.dsp.reload_config()`).
- **Tactical Briefing HUD & Keybind Casing Standardization**: Unified inline action descriptions across global, host-space (`hypr-host.lua`), and user-space (`user-keybinds.lua`) keybinds, with enhanced keycode mappings (`Brightness Up/Down`, `MSI Center`, and title-cased directional actions).
- **Installer Host Scale Synchronization**: Hardened `01-stow-configs.sh` to automatically sync display scaling (`SCALE`) from `profile.conf` into host `monitor.lua` during deployment.
- **Wallpaper State Preservation**: Hardened the installer deployment routine to cache and restore the active wallpaper state file, preventing wallpaper loss on reinstall.

---

## [v4.2.0] - 2026-10-14

### Added
- **Screenshot & Annotation Migration**: Migrated default screenshot annotation tool to Satty (`com.gabm.satty`), pruning deprecated `swappy` and redundant utility packages.
- **Clipboard Architecture Overhaul**: Unified terminal editor launches under `$TERMINAL`, integrated desktop discovery for clipboard paste operations, and eliminated fresh screenshot race conditions.

---

## [v4.0.0] - 2026-10-01

### Added
- **Complete Hyprland Lua Modernization**: Finalized migration of the core window manager configuration to modern Hyprland Lua syntax (`hl.*`, `hl.dsp.*`), ensuring native compatibility with Hyprland 0.55+.
- **Bilingual Control Script Engine**: Updated helper scripts (`mirror-hotplug.sh`, `wallpaper-selector.sh`, `waybar-switcher.sh`, `wlogout`, and `hypridle`) to support bilingual execution—executing Lua dispatchers (`hl.dsp.*`) first with seamless fallbacks to legacy dispatchers, eliminating interpreter syntax errors and accidental session termination.
- **Installer Host Auto-Bridging**: Upgraded `01-stow-configs.sh` to automatically detect legacy `.conf` user overrides (`user-keybinds.conf`, `user-windowrules.conf`, `user-visuals.conf`) and compile them to `.lua` via `hyprlang2lua` during deployment.
- **Desktop & Laptop Profile Template Parity**: Added missing `user-visuals.lua` and `user-windowrules.lua` templates for desktop environments and cleaned up legacy migration artifacts across host templates.
- **Waybar Switcher Race Condition Hardening**: Replaced naive process termination in `waybar-switcher.sh` with an explicit PID polling wait loop to ensure clean UI lifecycle reloads.
- **Dynamic Pywal Lua Export**: Updated `wallpaper-selector.sh` to populate `colors.lua` upon color scheme generation, followed by live `hyprctl reload`.
- **Interchangeable Hypridle & Hyprlock Architecture**: Elevated `hypridle.conf` and `hyprlock.conf` to first-class interchangeable host modules (Host First, Default Fallback). Allows hosts (e.g. desktops vs. laptops) to fully customize or omit listeners without rigid variable constraints, while maintaining seamless fallback to core defaults.

---

## [v3.3.0] - 2026-09-12

### Added
- **Decoupled Heavy Media Assets**: Decoupled all `.mp4` video wallpapers and SDDM login cinematics from Git into GitHub Release assets (`fetch-media.sh`). Reduced Git clone payload from >500 MB down to **~75 MB**.
- **Hardware Auto-Alignment**: Integrated dynamic backlight detection in `swaync-start.sh` (supporting both `amdgpu_bl*` and `intel_backlight`) and dynamic touchpad hardware detection in the installer.
- **Hypridle & Hyprlock Resilience**: Refactored `hypridle` with an overrideable `$TIMEOUT_*` variable architecture to eliminate duplicate listener conflicts, and enabled `immediate_render = true` in `hyprlock` to eliminate wake-from-suspend black screens.
- **Bloat Pruning & Image Optimization**: Converted oversized 29 MB raw PNG into an optimized 4K JPG (1.5 MB), purged 500+ lines of unreferenced prototype shell scripts, and streamlined dependencies in `00-dependencies.sh`.
- **Unified Power Protocol**: Consolidated power cycling logic across Waybar and SwayNC into a single source of truth (`power_cycle.sh`).
- **Resilient Environment**: Added dynamic `$EDITOR` fallback in `.zshrc` (`nvim` ➔ `micro` ➔ `nano` ➔ `vi`) and `timeout 1s` safety buffer on `upower` queries in Waybar.

---

## [v3.1.0] - 2026-08-20

### Added
- **Multi-API Media Engine**: Expanded the media selector (`pilot-hydra.py`) to support **Giphy** alongside **Klipy**, automatically selecting Giphy if configured.
- **Unified GTK Media Hub**: Consolidated animated GIFs, Klipy stickers, local stickers, and dynamic emojis into the native GTK3 `pilot-hydra.py` application (`Super + Shift + E`).
- **Configuration Cleanups**: Replaced legacy `.conf` commented templates in host vaults with valid, native Lua table comments.
- **Setup Guide Relocation**: Consolidated individual setup documents into a single, clean, jargon-free `DIY_GUIDE.md` in the repository root.

---

## [v3.0.0] - 2026-07-28

### Added
- **Native Lua Architecture**: Upgraded the entire core repository and Host Vaults from the legacy `.conf` format to Hyprland's native, high-performance `.lua` configuration parser.
- **Automated Migration Tool**: Developed `installer/scripts/migrate-to-lua.sh` to translate legacy user configurations, device blocks, and environment variables into perfect Lua syntax.
- **App Launcher Keybinds**: Rewrote the Rofi keybind helper backend (`lib-bind-engine.sh`) to natively parse Lua, preserving custom layout metadata and shortcuts.
- **Installer Improvements**: Upgraded the installer to dynamically generate `.lua` state files (keyboard/touchpad logic) while explicitly shielding standalone utilities (Hypridle/Hyprlock/Hyprsunset) from breaking.

---

## [v2.2.0] - 2026-06-15

### Added
- **Wallpaper Auto-Pause**: Added dynamic wallpaper auto-pause (`-p` / `--auto-pause`) to `mpvpaper` live wallpaper rendering. Automatically halts decoding when hidden under windows, slashing CPU overhead to 0% and massively extending battery life while working.
- **SwayNC Link-Break Protection**: Hardened `waybar-switcher.sh` to automatically detect and break GNU Stow symlinks for SwayNC configuration files upon position synchronizations. Blocks local transient coordinate settings from polluting the Git tracking tree.
- **Keybind Sourcing Priority**: Purged keybind double-sourcing from modular configurations, ensuring that host-specific user overrides are sourced strictly at the end of the Hyprland lifecycle to eradicate double-triggering.
- **Full Proton Compatibility**: Deployed dynamic hardware drivers for hybrid architectures (`lib32-vulkan-intel`, `lib32-vulkan-radeon`) as core installer dependencies for Steam/Proton compatibility.
- **Troubleshooting Tools**: Included Wayland Event Viewer (`wev`) as a default setup helper tool for easy keybind tracing, corrected audio lockups in `mic.sh` with a Pipewire settling delay, and removed deprecated VFR flags to safeguard display synchronization.

---

## [v1.4.0] - 2026-05-02

### Added
- **GTK Native Shift**: Completely purged KDE/Qt dependencies (Dolphin, Ark, KIO) in favor of lightweight GTK native equivalents (Thunar, File-Roller, Tumbler).
- **Polkit Isolation Fix**: Resolved systemd race conditions by directly launching the authentication agent natively as a child process of Hyprland.
- **User Overrides Integrity**: Fixed critical flaw in master config to properly source and prioritize host-specific user overrides (`user-keybinds.lua`, `user-windowrules.lua`, `user-visuals.lua`).
- **System Identity Engine**: Added `02-system-identity.sh` module to the installer for better shell and environment bootstrapping.

---

## [v1.3.0] - 2026-04-10

### Added
- **Improved Switcher Engine**: Refactored `waybar-switcher.sh` with **Axis-Lock** intelligence and **Link-Break** source protection.
- **Vault Centralization**: Migrated all machine-specific identity (`monitor.lua`, `nvidia.lua`, `touchpad.lua`) into isolated host vaults.
- **Desktop Management Tools**: Implemented the `pilot-control` CLI and GUI for system management.
- **Discovery Engine**: Refactored the Wallpaper Selector to support dual-library discovery for personal assets.

---

## [v1.2.0] - 2026-03-22

### Added
- **Hardware Detection**: Implemented auto-detection and driver deployment for various GPU architectures (NVIDIA/Intel/AMD).
- **Workspace Isolation**: Migrated high-workflow workspace clusters to host-specific vaults.
- **Shell Hardening**: Implemented the machine-agnostic `shell.local` profile hook.

---

## [v1.1.0] - 2026-03-01

### Added
- **Visual Effects**: Implemented the cinematic optics engine with 11 vision modes.
- **Hardware Agnostic**: Fully decoupled all UI geometry from hardcoded pixel values.
- **Hardening**: Completed the `hosts/` isolation and `.gitignore` security logic.
- **Internationalization**: Switched to physical keycodes for total layout independence.
