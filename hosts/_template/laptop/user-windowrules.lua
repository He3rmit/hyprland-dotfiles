-- Personal Window Rules Template
-- ──────────────────────────────────────────────────────────────────────────────
-- Purpose: Add specific rules for how windows behave on THIS machine.
-- Useful if you use different apps on your desktop vs your laptop.
-- ──────────────────────────────────────────────────────────────────────────────

-- --- WORKSPACE ASSIGNMENTS ---
-- Force specific apps to always open on a specific workspace
-- hl.window_rule({ match = { class = "^(discord)$" }, workspace = "3" })
-- hl.window_rule({ match = { class = "^(obsidian)$" }, workspace = "4" })

-- --- SPECIAL WORKSPACES ---
-- Pin an app to a hidden 'Special' workspace that you toggle with a keybind
-- hl.window_rule({ match = { class = "^(code-url-handler)$" }, workspace = "special:work" })
-- hl.window_rule({ match = { class = "^(Spotify)$" }, workspace = "special:hobby" })

-- --- OPACITY OVERRIDES ---
-- Want your terminal more transparent on your desktop but solid on your laptop?
-- Set opacity: active, inactive
-- hl.window_rule({ match = { class = "^(kitty)$" }, opacity = "0.8 0.7" })

-- --- FLOATING RULES ---
-- Force an app to always open as a floating window
-- hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
-- hl.window_rule({ match = { class = "^(pavucontrol)$" }, size = "800 600" })
