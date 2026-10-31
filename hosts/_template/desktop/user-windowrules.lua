-- Personal Window Rules (Desktop Template)
-- ──────────────────────────────────────────────────────────────────────────────
-- Purpose: Desktop window rules, workspace assignments, and multi-monitor routing.
-- ──────────────────────────────────────────────────────────────────────────────

-- --- WORKSPACE ASSIGNMENTS ---
-- Force specific apps to always open on a specific workspace or monitor
-- hl.window_rule({ match = { class = "^(discord)$" }, workspace = "3" })
-- hl.window_rule({ match = { class = "^(obsidian)$" }, workspace = "4" })
-- hl.window_rule({ match = { class = "^(steam)$" }, workspace = "5" })

-- --- GAMING RULES (Tearing/Immediate Mode) ---
-- Enable immediate mode (screen tearing) for Steam games to bypass VSync latency
-- hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, immediate = true })

-- --- FLOATING RULES ---
-- Force dialogs or mixers to open as floating windows
-- hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
-- hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })

-- Picture-in-Picture floating & pinned on top (already defined globally in modules/windowrules.lua)
-- hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })

-- --- HYPRLAND 0.57+ RULES [TEMPLATE] ---
-- Custom per-window visual exceptions
-- hl.window_rule({ match = { class = "^(your_app)$" }, no_wobble = true }) -- Disable wobble for specific app
-- hl.window_rule({ match = { class = "^(your_app)$" }, no_glow = true })   -- Disable glow for specific app
-- hl.window_rule({ match = { class = "^(your_app)$" }, no_xdg_drags = true }) -- Disallow xdg drag operations
