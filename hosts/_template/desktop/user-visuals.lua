-- Host-Specific Visual Overrides (Desktop Template)
-- ──────────────────────────────────────────────────────────────────────────────
-- Purpose: Customize animations, VRR, tearing, and performance on desktop hardware.
-- ──────────────────────────────────────────────────────────────────────────────

hl.config({
    general = {
        -- Enable tearing (immediate mode) for low-latency desktop gaming
        allow_tearing = true,
    },
    misc = {
        -- Variable Refresh Rate (0 = off, 1 = on, 2 = fullscreen only)
        -- Set to 2 if your gaming monitor supports G-Sync / FreeSync (avoids desktop video playback flicker)
        vrr = 0,
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
    },
    render = {
        -- Direct scanout can provide zero-latency fullscreen on pure AMD/Intel setups
        -- Set to false if experiencing multi-monitor flickering or on NVIDIA setups
        direct_scanout = false,
    },
    xwayland = {
        -- Prevents blurred rendering for X11/XWayland apps (e.g. Steam, Discord) when scaling
        force_zero_scaling = true,
    },
})
