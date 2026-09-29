-- LAPTOP SPECIFIC CONFIG — Template
-- ----------------------
-- Run `hyprctl monitors all` to find your precise monitor name and resolution
-- and replace the auto-detect line below.

-- Source the dynamic touchpad state (Laptop only)
require("touchpad")

-- 1. Input: Hardware Quirks

hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("~/.config/hypr/scripts/mirror-hotplug.sh"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/swaync/scripts/brightness.sh up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/swaync/scripts/brightness.sh down"), { locked = true, repeating = true })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("wlogout"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/swaync/scripts/volume.sh up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/swaync/scripts/volume.sh down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/swaync/scripts/volume.sh toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("~/.config/hypr/scripts/mic.sh toggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.config({
    input = {
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            drag_lock = true,
            disable_while_typing = true,
        },
        accel_profile = "adaptive",
        sensitivity = 0.5,
    },
    -- 3. Laptop Keybinds
    -- --- HARDWARE KEYS ---
    -- Bind physical laptop buttons (Fn keys) to specific actions.
    -- --- VOLUME & MEDIA & MIC ---
    -- --- HOST-SPECIFIC STARTUP APPS ---
    -- Launch daemons that are only needed on this specific machine.
    -- Example: Start a bluetooth applet if this machine has bluetooth
    -- hl.exec_cmd("sleep 2 && blueman-applet &")
    -- --- HOST-SPECIFIC ENVIRONMENT VARIABLES ---
    -- Example: Force screencasting to use Shared Memory (SHM) to fix EGL_BAD_MATCH CPU spikes on Intel
    -- hl.env("XDG_DESKTOP_PORTAL_HYPRLAND_FORCE_SHM", 1)
})

