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
        -- Variable Refresh Rate (1 = on, 2 = fullscreen only, 0 = off)
        -- Set to 1 or 2 if your gaming monitor supports G-Sync / FreeSync
        vrr = 1,
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
})
