# 🚀 Titanfall Pilot HUD — Operator Manual (v1.1.0)

> *"The HUD is modular. The Pilot is agnostic. The Titan is universal."*

## 1. Core Architecture — Modular vs. Personal
Your desktop is split into two layers to ensure total portability and privacy:
- **Core (`core/`, `hyprland/`)**: The shared "Engine" and "Visuals" that everyone uses.
- **Host (`hosts/`)**: Your machine's specific "Neuro-Link". This stores your private monitor resolution, scaling preferences, and personal keybinds.

---

## 2. Keybind Lexicon (mainMod = SUPER)

The Pilot's hand never leaves the tactical clusters. Shortcuts are organized into logical zones for high-speed operation.

### 🧩 Positional Workspace Logic (International Support)
The workspace binds use **Physical Keycodes**, not characters. Result: your hand movement is identical regardless of keyboard layout (QWERTY, AZERTY, etc.).
- **Super + [1-0]**: Switch to Workspaces 1-10.
- **Super + [F1-F12]**: Switch to Special Workspaces 11-22.
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

### 🎯 Cluster 2: The Buckets (Special Workspaces)
*The Home Row (A-S-D-F-G) provides instant access to categorical "scratchpads".*
| Key | Action |
|:---|:---|
| `Super + S` | **Standard** (Daily tasks) |
| `Super + W` | **Work** (Code/Dev) |
| `Super + H` | **Hobby** (Creation/Art) |
| `Super + G` | **Gaming** (Steam/Social) |
| `Super + T` | **Tools** (System/Terminals) |

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
| `Super + Alt + B` | **Waybar Theme** Switcher |
| `Super + Shift + V` | **Clipboard History** (Rofi) |
| `Ctrl + Shift + S` | **Screenshot** (Area/Annotate) |
| `Print` | **Screenshot** (Full/Clipboard) |

---

## 3. 📺 Pilot Vision Optics Engine
The framework features a sophisticated ImageMagick-powered engine for cinematic wallpaper effects. This is resolution-agnostic and scales to your hardware.

**Key Modes:**
- **Bloom (Cinematic)**: Adds a soft "Film Halation" glow to highlights.
- **Vanguard Tactical**: Teal/Orange grading + Hexagonal Honeycomb + Curved Visor.
- **BT-7274 Thermal**: Red/Yellow "Heatvision" + Scanlines + Pilot Reticle.
- **Cyber HUD**: Cyan/Magenta "Neon-Noir" + Digital Scanlines + Curved Visor.
- **Glitch (Purge)**: High-intensity chromatic aberration shift.
- **CRT Retro**: Analog TV scanlines and color bleeding.

---

## 4. 🛠️ Migration Blueprint (The "Neuro-Link" Transfer)
If you are moving from a legacy monolithic installation to this hardened framework, follow this guide to preserve your personal data.

### Phase 1: Identify Your Legacy Overrides
In your old installation, your personal "soul" lived in these files:
- `~/.config/hypr/modules/user-keybinds.conf` (Your app shortcuts)
- `~/.config/hypr/modules/hypr-host.conf` (Touchpad, Sensitivity, Laptop rules)
- `~/.config/hypr/modules/monitor.conf` (Old resolution rules)

### Phase 2: Bootstrap Your New Identity
Before moving files, you must create a new "Host Profile" in the new repository.
1. Enter your new dotfile directory: `cd ~/dotfiles`
2. Launch the deployment terminal: `./installer/install.sh`
3. Select **"+ Create New Profile"** and name it (e.g., `pilot-precision`).

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

## 5. Display Calibration & Scaling
Your monitor rule is now **Dynamic**. 

1.  **Monitor Wizard**: During installation, select your monitor and the script will generate a custom `monitor.conf`.
2.  **Scale Factor**: If icons look too small, re-run the wizard and choose a higher scale (e.g. 1.25 or 1.5). 
3.  **Optics Sync**: The Wallpaper Effects engine reads this scale factor to ensure HUD reticles and scanlines look correctly sized on your specific display.

---

## 6. Security & Git Hygiene
The project uses a **Black-Hole .gitignore** strategy:
- All folders in `hosts/` (except `_template`) are automatically ignored.
- The `hyprland/modules/colors.conf` (Pywal output) is ignored.
- **Result**: You can fork and push your repository to GitHub without leaking your hardware names, local monitor setups, or personal color palettes.

---

**Protocol 3: Protect the Pilot.** 🦾 🛡️ 
