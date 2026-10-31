-- Host-Specific Visual Overrides Template
-- ──────────────────────────────────────────────────────────────────────────────
-- Purpose: Override core visuals if this specific machine has weak hardware.
-- ──────────────────────────────────────────────────────────────────────────────

-- --- PERFORMANCE TWEAKS FOR WEAK LAPTOPS ---
-- Uncomment the blocks below if your donor laptop lags.

-- hl.config({
--     decoration = {
--         blur = { enabled = false },      -- Disabling blur saves a massive amount of GPU power
--         shadow = { enabled = false },    -- Disabling shadows helps performance
--     },
--     animations = {
--         enabled = false,                  -- Turns off all animations for an instant, snappy feel
--     }
-- })

-- ──────────────────────────────────────────────────────────────────────────────
--  HARDWARE OPTIMIZATIONS
-- ──────────────────────────────────────────────────────────────────────────────

hl.config({
    misc = {
        -- Variable Refresh Rate (Not supported on most laptops, keep disabled)
        vrr = 0,
        -- Essential HUD settings
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
    },
    render = {
        direct_scanout = 0,
    },
    -- --- HYPRLAND 0.57+ EFFECTS [TEMPLATE] ---
    -- decoration = {
    --     wobble = {
    --         enabled = false,      -- Compiz-style elastic window deformation
    --     },
    --     glow = {
    --         enabled = false,      -- Inner window edge glow
    --     },
    --     blur = {
    --         proportional = false, -- Proportional blur scaling (v0.57+)
    --     },
    -- },
    -- cursor = {
    --     warp_on_monitor_change = false, -- Cursor warping across monitor switches (v0.57+)
    -- },
})

