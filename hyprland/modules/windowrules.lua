-- -----------------------------------------------------
-- WINDOW RULES
-- -----------------------------------------------------

-- Suppress maximize events from all apps so they tile properly
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- --- GAME RULES [TEMPLATE] ---
-- For niche high-performance gaming (Tearing/Immediate Mode).
-- 1. Use 'hyprctl clients' to find the binary class.
-- 2. Add 'hl.window_rule({ match = { class = "^(your_game_here)$" }, immediate = true })' below.
-- 3. Ensure 'allow_tearing = true' is set in your user-visuals.lua.
-- ──────────────────────────────────────────────────────────────────────────────
--  Uncomment and customize in your local user-windowrules.lua.
-- ──────────────────────────────────────────────────────────────────────────────
-- hl.window_rule({ match = { class = "^(payday2_win32_release.exe)$" }, immediate = true })
-- hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, immediate = true })

-- --- WORKSPACE RULES ---
-- Smart gaps (No gaps when only 1 window)

hl.workspace_rule({
    workspace = "w[tv1]",
    gaps_out = 0,
    gaps_in = 0,
    no_border = true,
})

hl.workspace_rule({
    workspace = "f[1]",
    gaps_out = 0,
    gaps_in = 0,
    no_border = true,
})

-- --- SPECIAL APPS AUTOMATION [TEMPLATE] ---
-- Force specific apps to workspaces or set silent launch rules here.
-- Uncomment and customize in your local user-windowrules.lua.
-- ──────────────────────────────────────────────────────────────────────────────
-- hl.window_rule({ match = { class = "^(code-url-handler)$" }, workspace = "special:work" })
-- hl.window_rule({ match = { class = "^(Spotify)$" }, workspace = "special:hobby" })

-- --- MEDIA & CLIPBOARD PREVIEW FLOATING RULES ---
hl.window_rule({ match = { class = "^(imv)$" }, float = true, center = true, size = "1000 650" })
hl.window_rule({ match = { class = "^(swappy)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^(com.gabm.satty)$" }, float = true, center = true })
hl.window_rule({ match = { title = "^(Clip-Preview)$" }, float = true, center = true, size = "960 540" })
