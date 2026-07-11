-- ==============================================================================
-- TITANFALL PILOT HUD — USER KEYBINDS
-- Purpose: Add your custom app launchers, workspace toggles, or overrides here.
--          This file is host-specific and will NEVER be touched by core updates.
-- ==============================================================================

-- --- APP LAUNCHERS ---
-- Example: Open Obsidian with Super + O
-- hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("obsidian"))
-- Example: Open Discord on Workspace 3 specifically
-- hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("[workspace 3] discord"))

-- --- CUSTOM WORKSPACES ---
-- Example: A hidden "Special" workspace for a chat app
-- hl.bind(mainMod .. " + SPACE", hl.dsp.workspace.toggle_special("chat"))
-- hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.move({ workspace = "special:chat" }))

-- --- OVERRIDING CORE BINDS ---
-- Example: If you want to change a core bind (e.g. Super + Q to close), 
-- you MUST unbind it first before re-binding it here:
-- hl.unbind(mainMod .. " + Q")
-- hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("alacritty"))
