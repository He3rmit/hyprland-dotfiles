-- -----------------------------------------------------
-- MONITOR CONFIGURATION (LAPTOP TEMPLATE)
-- -----------------------------------------------------
-- Run 'hyprctl monitors all' in your terminal to find your exact display name.
-- Replace the 'eDP-1' below with your actual display name.

-- --- BASIC SETUP ---
-- Example: Standard 1080p display (No scaling)
hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = "1",
})

-- --- HIGH-DPI SCALING (4K or Retina displays) ---
-- Set scale to 1.5 or 2 to make text readable
-- hl.monitor({ output = "eDP-1", mode = "3840x2160@60", position = "0x0", scale = "2" })

-- --- EXTERNAL DISPLAYS ---
-- Place the external monitor to the right of your laptop screen
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "1920x0", scale = "1" })

-- --- MIRRORING (Presentations/Projectors) ---
-- Make the external HDMI mirror the laptop screen
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = "1", mirror = "eDP-1" })

-- --- FALLBACK (Keep this uncommented to ensure something always displays) ---
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1",
})

