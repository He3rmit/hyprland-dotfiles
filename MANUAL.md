# 🚀 Titanfall Pilot HUD — Operator Manual (v1.3.0)

> *"The HUD is modular. The Pilot is agnostic. The Titan is universal."*

## 1. Core Architecture — The Vault Standard
Your desktop is split into two layers to ensure total portability and privacy:
- **Core (`core/`, `hyprland/`)**: The shared "Engine" and "Visuals" that everyone uses. This code remains 100% hardware-agnostic and "Read-Only."
- **Host (`hosts/`)**: Your machine-specific "Neuro-Link". This stores your private monitor resolution, scaling preferences, world-exclusive keybinds, and hardware drivers in a Git-ignored vault.

---

## 2. Keybind Lexicon (mainMod = SUPER)

The Pilot's hand never leaves the tactical clusters. Shortcuts are organized into logical zones for high-speed operation.

### 🧩 Tactical Discovery (Hints for Pilots)
To quickly learn the cockpit's operational binds without reading the manual:
1.  **Searchable Briefing**: Press `Super + Alt + /` to launch the **Tactical Briefing**.
2.  **Visual Discovery**: Click the **Question Mark (``)** in your Waybar stack.
3.  **Real-Time Parsing**: This menu scans your actual configuration—it always reflects your current active binds.

### 🧩 Positional Workspace Logic (International Support)
The workspace binds use **Physical Keycodes**, not characters. Result: your hand movement is identical regardless of keyboard layout (QWERTY, AZERTY, etc.).
- **Super + [1-0]**: Switch to Workspaces 1-10 (Global Engine).
- **Super + [F1-F12]**: Switch to Special Workspaces 11-22 (Personal Vault — see Section 4).
- **Super + Shift + [1-0]**: Move window to workspace.

### 🚀 Cluster 1: The Launchpad (Launching & Optics)
| Key | Action |
|:---|:---|
| `Super + Q` | **Terminal** (Foot) |
| `Super + E` | **File Manager** (Thunar) |
| `Super + R` | **App Launcher** (Rofi Drun) |
| `Super + Ctrl + R` | **Command Runner** (Rofi Run) |
| `Super + Alt + W` | **Wallpaper Selector** |
| `Super + Alt + E` | **Pilot Vision / Effects Menu** |
| `Super + Alt + /` | **Tactical Briefing** (Searchalble Cheat Sheet) |

### 🎯 Cluster 2: The Buckets (Personal Workspace Vault)
*These are now host-specific personal shortcuts. Templates are provided in the global config.*
| Key | Action | Location |
|:---|:---|:---|
| `Super + S` | **Standard** (Daily tasks) | `hosts/[profile]/user-keybinds.conf` |
| `Super + W` | **Work** (Code/Dev) | `hosts/[profile]/user-keybinds.conf` |
| `Super + H` | **Hobby** (Creation/Art) | `hosts/[profile]/user-keybinds.conf` |
| `Super + G` | **Gaming** (Steam/Social) | `hosts/[profile]/user-keybinds.conf` |
| `Super + T` | **Tools** (System/Terminals) | `hosts/[profile]/user-keybinds.conf` |

### 🪟 Cluster 3: Window State (Bottom Left)
| Key | Action |
|:---|:---|
| `Super + C` | **Kill Active** Window |
| `Super + V` | Toggle **Floating** |
| `Super + F` | Toggle **Fullscreen** |
| `Super + J` | Toggle **Split/Join** (Master Layout) |
| `Super + P` | Toggle **Pseudo** |

### 🛰️ Cluster 4: System & UI (Right Hand)
| Key | Action |
|:---|:---|
| `Super + N` | **Notification Center** (Pilot HUD) |
| `Super + L` | **Screen Lock** (Hyprlock) |
| `Super + B` | **Cycle Waybar** Layout |
| `Super + Alt + B` | **Waybar Switcher** (Gen 2) |
| `Super + Shift + V` | **Clipboard History** | Browse and paste clipboard history (Rofi). |
| `Super + Shift + E` | **Media Hub** | Launch the Hydra (Emoji/GIF/Stickers) picker. |
| `Super + N` | **Notifications** | Toggle the swaync notification panel. |
| `Print` | **Screenshot** (Full/Clipboard) |

---

## 3. Pilot-Control Suite (The Management Chassis)
The HUD includes a unified management tool called `pilot-control`. It handles high-level system states that standard keybinds cannot reach.

### 🎮 The GUI (Tactile Interface)
Launch the **Pilot Control Center** by clicking the **Settings** or **Power** icon in Waybar, or run:
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
- **Axis-Lock Intelligence**: The switcher recognizes if you are using a **Sidebar** (Vertical) or **Topbar** (Horizontal). It automatically restricts "Direction" choices and position memory to prevent rendering glitches.
- **Engine Restart**: The HUD performs a full "Engine Restart" during switches to guarantee 100% configuration persistence.

### 🧩 Pilot Vision Optics
The framework features a sophisticated ImageMagick-powered engine for cinematic wallpaper effects. This is resolution-agnostic and scales to your hardware.

**Key Modes:**
- **Bloom (Cinematic)**: Adds a soft "Film Halation" glow to highlights.
- **Vanguard Tactical**: Teal/Orange grading + Hexagonal Honeycomb + Curved Visor.
- **BT-7274 Thermal**: Red/Yellow "Heatvision" + Scanlines + Pilot Reticle.
- **Cyber HUD**: Cyan/Magenta "Neon-Noir" + Digital Scanlines + Curved Visor.
- **Glitch (Purge)**: High-intensity chromatic aberration shift.
- **CRT Retro**: Analog TV scanlines and color bleeding.

---

## 5. 🛠️ Migration Blueprint (The "Neuro-Link" Transfer)
If you are moving from a legacy monolithic installation to this hardened framework, follow this guide to preserve your personal data.

### Phase 1: Identify Your Personal Vaults
In this framework, your "soul" lives in your host-specific folder:
- `hosts/[profile]/user-keybinds.conf`: Stores Cluster 2 (The Buckets) and Cluster 6 (F-Keys).
- `hosts/[profile]/user-windowrules.conf`: Machine-specific app behavior and gaming rules.
- `hosts/[profile]/user-visuals.conf`: Hardware-specific rendering and visual comfort.
- `hosts/[profile]/monitor.conf`: Your machine's specific monitor/resolution rules.
- `hosts/[profile]/nvidia.conf`: (Optional) NVIDIA driver environmental variables.
- `hosts/[profile]/hypr-host.conf`: Hardware-specific triggers (Volume, Power, etc.).
- `hosts/[profile]/shell.local`: Stores your machine-specific shell aliases and variables.

### Phase 2: Active Deployment
1. Enter your dotfile directory: `cd ~/dotfiles`
2. Launch the deployment terminal: `./installer/install.sh`
3. The installer now features the **Hardware Trinity** engine—it will auto-detect your GPU and deploy the correct Vulkan/VA-API acceleration modules for NVIDIA, Intel, or AMD.

### Phase 3: The Handover (Data Migration)
Now, manually move your legacy data into your new protected host folder. 
Replace `[your-profile]` with the name you just created:

```bash
# 1. Move your personal keybinds
cp ~/.config/hypr/modules/user-keybinds.conf ~/dotfiles/hosts/[your-profile]/

# 2. Move your hardware-host rules
cp ~/.config/hypr/modules/hypr-host.conf ~/dotfiles/hosts/[your-profile]/

# 3. Final Deployment (Stow)
./installer/install.sh
# -> Select [your-profile]
# -> Select [01-stow-configs]
```

---

## 6. Display Calibration & Scaling (Optics Protocol)
Your monitor rule is now **Dynamic** and part of your Vault.

1.  **Monitor Wizard**: During installation, select your monitor and the script will generate a custom `monitor.conf` in your vault.
2.  **Resolution Agnosticism**: Waybar is a native Wayland client. If you are on a 4K screen, set your `scale` to `2` in `monitor.conf`. Waybar will automatically follow this multiplier, ensuring your HUD maintains perfect "Visual Weight" without code changes.
3.  **Optics Sync**: The Wallpaper Effects engine reads this scale factor to ensure HUD reticles and scanlines look correctly sized on your specific display.

---

## 7. Security & Git Hygiene
The project uses a **Black-Hole .gitignore** strategy:
- All folders in `hosts/` (except `_template`) are automatically ignored.
- The `hyprland/modules/colors.conf` (Pywal output) is ignored.
- **Result**: You can fork and push your repository to GitHub without leaking your hardware names, local monitor setups, or personal color palettes.

---

**Protocol 3: Protect the Pilot.** 🦾 🛡️ 
