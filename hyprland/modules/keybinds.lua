-- -----------------------------------------------------
-- KEYBINDINGS :: TITAN CLUSTER
-- -----------------------------------------------------

-- global mainMod is provided by hyprland.lua

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 1: THE LAUNCHPAD (Super + Key)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(runner))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout current next")) -- Cycle keyboard layout

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 2: UI SWITCHERS & THEMING (Super + Alt + Key)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-selector.sh"))
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-effects.sh"))
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/waybar-switcher.sh"))
hl.bind(mainMod .. " + ALT + slash", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds-hint.sh"))

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 3: SYSTEM HUBS (Super + Shift + Key)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi-network.sh"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi-bluetooth.sh"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/hypr/scripts/cliphist-rofi.sh"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("~/.config/hypr/scripts/pilot-hydra.py"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/gamemode.sh")) -- Toggle Game Mode (Performance Boost)

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 4: CAPTURE & MEDIA TOOLS (Print & Screen Recording)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot-swappy.sh"))
hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot-swappy.sh"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/recorder.sh"))
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/recorder.sh --fullscreen"))

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 5: WINDOW STATE (Bottom Left: C-V-F-P-J)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 6: SYSTEM CONTROLS (Lock & Notification & Power)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/waybar/scripts/power_cycle.sh"))

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 7: SPECIAL WORKSPACES (Scratchpads) [TEMPLATE]
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad" }))

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 8: NAVIGATION (Arrows & Standard 1-10)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 9: EXPANDED WORKSPACES (F1-F12 -> 11-22) [TEMPLATE]
--  Uncomment and customize in your local user-keybinds.lua if needed.
-- ──────────────────────────────────────────────────────────────────────────────
-- hl.bind(mainMod .. " + code:67", hl.dsp.focus({ workspace = 11 }))            -- code:67 = F1
-- hl.bind(mainMod .. " + code:68", hl.dsp.focus({ workspace = 12 }))            -- code:68 = F2
-- hl.bind(mainMod .. " + code:69", hl.dsp.focus({ workspace = 13 }))            -- code:69 = F3
-- hl.bind(mainMod .. " + code:70", hl.dsp.focus({ workspace = 14 }))            -- code:70 = F4
-- hl.bind(mainMod .. " + code:71", hl.dsp.focus({ workspace = 15 }))            -- code:71 = F5
-- hl.bind(mainMod .. " + code:72", hl.dsp.focus({ workspace = 16 }))            -- code:72 = F6
-- hl.bind(mainMod .. " + code:73", hl.dsp.focus({ workspace = 17 }))            -- code:73 = F7
-- hl.bind(mainMod .. " + code:74", hl.dsp.focus({ workspace = 18 }))            -- code:74 = F8
-- hl.bind(mainMod .. " + code:75", hl.dsp.focus({ workspace = 19 }))            -- code:75 = F9
-- hl.bind(mainMod .. " + code:76", hl.dsp.focus({ workspace = 20 }))            -- code:76 = F10
-- hl.bind(mainMod .. " + code:95", hl.dsp.focus({ workspace = 21 }))            -- code:95 = F11
-- hl.bind(mainMod .. " + code:96", hl.dsp.focus({ workspace = 22 }))            -- code:96 = F12
-- ──────────────────────────────────────────────────────────────────────────────

-- [ hardware-trigger ] Media & Audio binds moved to host vault

-- Mouse Interaction
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())
