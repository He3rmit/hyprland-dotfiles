-- DESKTOP SPECIFIC CONFIG
-- -----------------------

-- 1. Input: Hardware Quirks

-- Media & Audio Controls (standard keyboard keys)
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
        sensitivity = 0,
    },
    -- 2. Desktop Keybinds
    -- (Add any macro keys or specific desktop tools here)
    -- --- HOST-SPECIFIC ENVIRONMENT VARIABLES ---
    -- Example: Force screencasting to use Shared Memory (SHM) to fix EGL_BAD_MATCH CPU spikes on Intel
    -- hl.env("XDG_DESKTOP_PORTAL_HYPRLAND_FORCE_SHM", 1)
})

