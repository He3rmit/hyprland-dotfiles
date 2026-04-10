# 🚀 Titanfall Pilot HUD — Operator Manual (v1.1.0)

> *"The HUD is modular. The Pilot is agnostic. The Titan is universal."*

## 1. Core Architecture — Modular vs. Personal
Your desktop is split into two layers to ensure total portability and privacy:
- **Core (`core/`, `hyprland/`)**: The shared "Engine" and "Visuals" that everyone uses.
- **Host (`hosts/`)**: Your machine's specific "Neuro-Link". This stores your private monitor resolution, scaling preferences, and personal keybinds.

---

## 2. Keybind Reference ($mainMod = SUPER)

### 🧩 Positional Workspace Logic (International Support)
The workspace binds in this framework use **Physical Keycodes**, not characters. Result: your muscle memory remains identical regardless of layout.
- **Super + [1-0]**: Switch to Workspaces 1-10.
- **Super + [F1-F12]**: Switch to Special Workspaces 11-22.
- **Super + Shift + [1-0]**: Move window to workspace.

### 🛰️ The Pilot HUD (SwayNC) — `Super + N`
Your notification center acts as a tactical control panel:
- **WiFi Indicator**: Click to toggle (managed by `nm-applet`).
- **Power Modes**: Balanced / Power Saver / Performance.

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

## 4. 🛠️ Migration Blueprint (For Legacy Users)
If you are moving from a monolithic repository, follow these steps to "Harden" your install:

### Step 1: Initialize New Host
Run the installer and create a new profile for your machine:
```bash
./installer/install.sh
# Select: CREATE NEW PROFILE
```

### Step 2: Migrate Personal Files
Move your machine-specific overrides into the newly created `hosts/[your-host]/` folder:
```bash
mv ~/.config/hypr/modules/user-keybinds.conf ~/dotfiles/hosts/[your-host]/
mv ~/.config/hypr/modules/hypr-host.conf ~/dotfiles/hosts/[your-host]/
```

### Step 3: Deployment
Re-run the installer to "Stow" the new modular structure:
```bash
./installer/install.sh
# Select: [01-STOW-CONFIGS]
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
