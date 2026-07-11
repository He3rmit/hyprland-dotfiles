# 🚀 Titanfall Pilot HUD — Operator Manual (v3.1.0)

> *"A modular, portable, and universal desktop environment."*

## 1. Core Architecture — The Profile Standard
Your desktop is split into two layers to ensure total portability and privacy:
- **Core (`core/`, `hyprland/`)**: The shared "Engine" and "Visuals" that everyone uses. This code remains 100% hardware-agnostic and "Read-Only."
- **Host (`hosts/`)**: Your machine-specific "Local Configuration". This stores your private monitor resolution, scaling preferences, world-exclusive keybinds, and hardware drivers in a Git-ignored directory.

### 🛡️ The Golden Rule of Profiles
**Never edit configuration files directly in `~/.config/`.** 
Because the deployment engine uses automated cleanup to guarantee a clean slate, any real files or manual overrides placed directly in `~/.config/` will be **safely overwritten** during the next deployment. 
Always edit your configurations inside your `~/dotfiles/hosts/[your-profile]/` vault. The engine will safely link them for you.

---

## 1.5 The v2.1 "Atomic" Deployment Engine
The dotfiles installer is carefully designed to be 100% plug-and-play on **any pre-existing environment**. You do not need a clean OS to run the deployment.

1. **Automated Cleanup**: Before GNU Stow runs, the engine actively hunts down and removes all known cache files and explicit overrides. This guarantees Stow always sees a pristine environment and never aborts due to "existing target" conflicts. It even safely backs up your real `~/.zshrc`.
2. **Reliable Symlink Creation**: To defeat Hyprland's `inotify` watchdog (which automatically recreates a default config the millisecond `stow` unlinks it), `hyprland.lua` is completely ignored by GNU Stow (`.stow-local-ignore`). Instead, the engine uses a POSIX atomic replacement (`mv -T`) to swap the file instantly at the VFS inode level. The race condition is permanently solved.
3. **Strict `--no-folding`**: GNU Stow is explicitly banned from "folding" directories. It must always create real target directories and individual file symlinks. This permanently shields your Git repository from being polluted by accidental overrides following symlinks backward.
4. **SwayNC Link-Break Protection**: When `waybar-switcher.sh` dynamically synchronizes Waybar and SwayNC positions, it automatically detects if `~/.config/swaync/config.json` is a Stow symlink. If so, it instantly breaks the symlink and replaces it with a real local file copy. This prevents transient position coordinates from propagating backward through the symlink and polluting core repository files.


---

## 2. Keybind Lexicon (mainMod = SUPER)

Shortcuts are designed for minimal hand movement and organized into logical zones for high-speed operation.

### 🧩 Learning the Shortcuts
To quickly learn the desktop's operational binds without reading the manual:
1.  **Searchable Cheat Sheet**: Press `Super + Alt + /` to launch the **Searchable Cheat Sheet**.
2.  **Visual Discovery**: Click the **Question Mark (``)** in your Waybar stack.
3.  **Real-Time Parsing**: This menu scans your actual configuration—it always reflects your current active binds.

### 🧩 Positional Workspace Logic (International Support)
The workspace binds use **Physical Keycodes**, not characters. Result: your hand movement is identical regardless of keyboard layout (QWERTY, AZERTY, etc.).
- **Super + [1-0]**: Switch to Workspaces 1-10 (Global Engine).
- **Super + [F1-F12]**: Switch to Special Workspaces 11-22 (Personal Vault — see Section 4).
- **Super + Shift + [1-0]**: Move window to workspace.

### 🚀 Group 1: Basic App Launchers
| Key | Action |
|:---|:---|
| `Super + Q` | **Terminal** (Kitty) |
| `Super + E` | **File Manager** (Thunar) |
| `Super + R` | **App Launcher** (Rofi Drun) |
| `Super + Ctrl + R` | **Command Runner** (Rofi Run) |
| `Super + Alt + W` | **Wallpaper Selector** |
| `Super + Alt + E` | **Visual Effects Menu** |
| `Super + Alt + /` | **Tactical Briefing** (Searchalble Cheat Sheet) |

### 🎯 Group 2: Personal Workspaces
*The "Standard" special workspace is enabled globally by default. You can create your own custom workspaces (like Work, Gaming, Hobby) in your local `hosts/[profile]/user-keybinds.lua` file.*
| Key | Action | Location |
|:---|:---|:---|
| `Super + S` | **Standard** (Daily tasks / Scratchpad) | `hyprland/modules/keybinds.lua` |

### 🪟 Group 3: Window Controls (Bottom Left)
| Key | Action |
|:---|:---|
| `Super + C` | **Kill Active** Window |
| `Super + V` | Toggle **Floating** |
| `Super + F` | Toggle **Fullscreen** |
| `Super + J` | Toggle **Split/Join** (Master Layout) |
| `Super + P` | Toggle **Pseudo** |

### 🛰️ Group 4: System & UI (Right Hand)
| Key | Action |
|:---|:---|
| `Super + N` | **Notification Center** |
| `Super + L` | **Screen Lock** (Hyprlock) |
| `Super + B` | **Power Cycle** Performance, Balanced, Silent |
| `Super + Alt + B` | **Waybar Switcher** (Gen 2) |
| `Super + Shift + V` | **Clipboard History** | Browse and paste clipboard history (Rofi). |
| `Super + Shift + E` | **Media Hub** | Launch the Hydra (Emoji/GIF/Stickers) picker. |
| `Print` | **Screenshot** (Full/Clipboard) |

---

## 3. Desktop Management Tools
The desktop includes a unified management tool called `pilot-control`. It handles high-level system states that standard keybinds cannot reach.

### 🎮 The Pilot Control Menu (System Settings & Customization)
If you want to customize system-level options (like enabling or disabling the SDDM login screen's cinematic video HUD, or running system integrity checks), you can launch the **Pilot Control Menu**. 

You can launch it by running this script in your terminal:
`~/.config/hypr/scripts/pilot-control-gui.sh`

### ⌨️ The CLI (Terminal Access)
For advanced operators, the `pilot-control` binary provides direct system hooks:
- `pilot-control sddm --disengage`: Safely restores default SDDM visuals (removes cinematic video overrides).
- `pilot-control bluetooth --toggle`: Tactical peripheral control.
- `pilot-control help`: Displays the full command manifest.

---

## 4. 📺 Pilot Vision & Waybar Engine
The HUD features two primary "Intelligence Layers" that adapt to your specific hardware.

### 🧩 Waybar "Generation 2" Engine
The switcher now operates on a **Link-Break Protocol** to ensure that switching themes or layouts never modifies your Git repository.
- **Smart Layout Constraints**: The switcher recognizes if you are using a **Sidebar** (Vertical) or **Topbar** (Horizontal). It automatically restricts "Direction" choices and position memory to prevent rendering glitches.
- **Clean Restart**: The HUD performs a full "Clean Restart" during switches to guarantee 100% configuration persistence.

### 🧩 Wallpaper Engine
The framework features a sophisticated ImageMagick-powered engine for cinematic wallpaper effects. This is resolution-agnostic and scales to your hardware.

**Key Modes:**
- **Bloom (Cinematic)**: Adds a soft "Film Halation" glow to highlights.
- **Vanguard Tactical**: Teal/Orange grading + Hexagonal Honeycomb + Curved Visor.
- **Thermal Vision**: Red/Yellow "Heatvision" + Scanlines.
- **Cyber HUD**: Cyan/Magenta "Neon-Noir" + Digital Scanlines + Curved Visor.
- **Glitch (Purge)**: High-intensity chromatic aberration shift.
- **CRT Retro**: Analog TV scanlines and color bleeding.

---

## 5. 🛠️ Migration Guide
If you are moving from a legacy monolithic installation to this hardened framework, follow this guide to preserve your personal data.

### Phase 1: Identify Your Personal Vaults
In this framework, your "soul" lives in your host-specific folder:
- `hosts/[profile]/user-keybinds.lua`: Stores Group 2 (Personal Workspaces) and Group 6 (F-Keys).
- `hosts/[profile]/user-windowrules.lua`: Machine-specific app behavior and gaming rules.
- `hosts/[profile]/user-visuals.lua`: Hardware-specific rendering and visual comfort.
- `hosts/[profile]/monitor.lua`: Your machine's specific monitor/resolution rules.
- `hosts/[profile]/nvidia.lua`: (Optional) NVIDIA driver environmental variables.
- `hosts/[profile]/hypr-host.lua`: Hardware-specific triggers (Volume, Power, etc.).
- `hosts/[profile]/shell.local`: Stores your machine-specific shell aliases and variables.

### Phase 2: Active Deployment
1. Enter your dotfile directory: `cd ~/dotfiles`
2. Launch the deployment terminal: `./installer/install.sh`
3. The installer now features **Hardware Detection**—it will auto-detect your GPU and deploy the correct Vulkan/VA-API acceleration modules for NVIDIA, Intel, or AMD.

### Phase 3: The Handover (Data Migration)
Now, manually move your legacy data into your new protected host folder. 
Replace `[your-profile]` with the name you just created:

```bash
# 1. Move your personal keybinds
cp ~/.config/hypr/user-keybinds.conf ~/dotfiles/hosts/[your-profile]/user-keybinds.lua

# 2. Move your hardware-host rules
cp ~/.config/hypr/host.conf ~/dotfiles/hosts/[your-profile]/hypr-host.lua

# 3. Final Deployment (Stow)
./installer/install.sh
# -> Select [your-profile]
# -> Select [01-stow-configs]
```

---

## 6. Display Calibration & Scaling
Your monitor rule is now **Dynamic** and part of your Vault.

1.  **Monitor Wizard**: During installation, select your monitor and the script will generate a custom `monitor.lua` in your vault.
2.  **Resolution Agnosticism**: Waybar is a native Wayland client. If you are on a 4K screen, set your `scale` to `2` in `monitor.lua`. Waybar will automatically follow this multiplier, ensuring your HUD maintains perfect "Visual Weight" without code changes.
3.  **Wallpaper Scaling**: The Wallpaper Effects engine reads this scale factor to ensure visual overlays and scanlines look correctly sized on your specific display.

---

## 7. Security & Git Hygiene
The project uses a **Black-Hole .gitignore** strategy:
- All folders in `hosts/` (except `_template`) are automatically ignored.
- The `hyprland/modules/colors.lua` (Pywal output) is ignored.
- **Result**: You can fork and push your repository to GitHub without leaking your hardware names, local monitor setups, or personal color palettes.

---

**Enjoy your custom desktop!** 🚀
