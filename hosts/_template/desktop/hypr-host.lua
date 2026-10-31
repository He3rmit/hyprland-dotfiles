-- DESKTOP SPECIFIC CONFIG
-- -----------------------

-- 1. Input: Hardware Quirks

-- Media & Audio Controls (standard keyboard keys)
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("wlogout")) -- Power Session Menu (Wlogout)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/swaync/scripts/volume.sh up"), { locked = true, repeating = true }) -- Volume Up
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/swaync/scripts/volume.sh down"), { locked = true, repeating = true }) -- Volume Down
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/swaync/scripts/volume.sh toggle"), { locked = true }) -- Mute Audio Output
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("~/.config/hypr/scripts/mic.sh toggle"), { locked = true }) -- Mute Microphone
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true }) -- Media Next
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- Media Play / Pause
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- Media Play / Pause
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true }) -- Media Previous

hl.config({
    input = {
        sensitivity = 0,
    },
})

-- 2. Desktop Keybinds & Custom Tools
-- (Add any macro keys or desktop-specific application hotkeys here)

-- 3. Host-Specific Environment Variables
-- Example: Force screencasting to use Shared Memory (SHM) to fix EGL_BAD_MATCH CPU spikes on Intel
-- hl.env("XDG_DESKTOP_PORTAL_HYPRLAND_FORCE_SHM", 1)

-- 4. Host-Specific Autostart Daemons
-- Launch background tools specific to this machine (e.g. RGB controllers, fan management)
hl.on("hyprland.start", function()
    -- hl.exec_cmd("openrgb --profile default -b 50 &")
    -- hl.exec_cmd("corectrl --minimize-systray &")
end)

