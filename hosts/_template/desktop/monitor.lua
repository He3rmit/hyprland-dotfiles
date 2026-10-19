-- -----------------------------------------------------
-- MONITOR CONFIGURATION (DESKTOP TEMPLATE)
-- -----------------------------------------------------
-- Run 'hyprctl monitors all' in your terminal to find your exact display connectors.

-- Universal Default (Auto-detects primary display at native resolution and refresh rate)
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1",
})

-- --- EXAMPLES ---
-- Single High-Refresh Gaming Monitor (1440p 144Hz):
-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = "1" })

-- Dual Monitor Setup (Main DP-1 at 0x0, Secondary HDMI-A-1 to the right):
-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = "1" })
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "2560x0", scale = "1" })

-- Portrait / Vertical Monitor (Rotated 90 degrees counter-clockwise):
-- hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "2560x0", scale = "1", transform = 1 })

-- 4K High-DPI Display (1.5x fractional scaling):
-- hl.monitor({ output = "DP-1", mode = "3840x2160@60", position = "0x0", scale = "1.5" })
