-- -----------------------------------------------------
-- KEYBINDINGS :: TITAN CLUSTER
-- -----------------------------------------------------

-- global mainMod is provided by hyprland.lua

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 1: THE LAUNCHPAD (Super + Key)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal)) -- Launch Terminal (Kitty)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager)) -- Launch File Manager (Thunar)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu)) -- Command Palette (Spotlight / Raycast)
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu)) -- Command Palette (Spotlight / Raycast)
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi-window.sh")) -- Window Switcher (All Workspaces)
hl.bind("ALT + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/window-quick-flip.sh")) -- Instant Window Flip (A/B Toggle)
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout current next")) -- Cycle Keyboard Layout

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 2: UI SWITCHERS & THEMING (Super + Alt + Key)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-selector.sh")) -- Wallpaper Selector
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-effects.sh")) -- Wallpaper Visual Effects
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/waybar-switcher.sh")) -- Waybar Layout & Style Switcher
hl.bind(mainMod .. " + ALT + slash", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds-hint.sh")) -- Tactical Briefing (Keybinds Cheat Sheet)

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 3: SYSTEM HUBS (Super + Shift + Key)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi-network.sh")) -- Network Manager (Wi-Fi / Ethernet)
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi-bluetooth.sh")) -- Bluetooth Device Manager
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/hypr/scripts/cliphist-rofi.sh")) -- Clipboard History Manager
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("~/.config/hypr/scripts/pilot-hydra.py")) -- Media Hub (Emojis / GIFs / Stickers)
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/gamemode.sh")) -- Toggle Game Mode (Performance Boost)

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 4: CAPTURE & MEDIA TOOLS (Print & Screen Recording)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy")) -- Full Screen Screenshot to Clipboard
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot-swappy.sh")) -- Region Screenshot & Annotate (Swappy)
hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot-swappy.sh")) -- Region Screenshot & Annotate (Swappy)
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/recorder.sh")) -- Screen Recorder (Select Region)
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/recorder.sh --fullscreen")) -- Screen Recorder (Fullscreen)

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 5: WINDOW STATE (Bottom Left: C-V-F-P-J)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + C", hl.dsp.window.close()) -- Close Active Window
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" })) -- Toggle Floating Mode
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })) -- Toggle Fullscreen Mode
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- Toggle Pseudo Tile
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- Toggle Split / Join Layout

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 6: SYSTEM CONTROLS (Lock & Notification & Power)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock")) -- Lock Screen (Hyprlock)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw")) -- Toggle Notification Center (SwayNC)
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/waybar/scripts/power_cycle.sh")) -- Cycle Power Profile (Performance / Balanced / Saver)
-- hl.bind(mainMod .. " + SHIFT + C", hl.dsp.reload_config()) -- Reload Hyprland Configuration (Native v0.57+)

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 7: SPECIAL WORKSPACES (Scratchpads) [TEMPLATE]
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("scratchpad")) -- Toggle Scratchpad Workspace
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad" })) -- Move Window to Scratchpad

-- ──────────────────────────────────────────────────────────────────────────────
--  CLUSTER 8: NAVIGATION (Arrows & Standard 1-10)
-- ──────────────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" })) -- Focus Window Left
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" })) -- Focus Window Right
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" })) -- Focus Window Up
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" })) -- Focus Window Down

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" })) -- Move Window Left
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" })) -- Move Window Right
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" })) -- Move Window Up
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" })) -- Move Window Down

hl.bind(mainMod .. " + code:10", hl.dsp.focus({ workspace = 1 })) -- Switch to Workspace 1
hl.bind(mainMod .. " + code:11", hl.dsp.focus({ workspace = 2 })) -- Switch to Workspace 2
hl.bind(mainMod .. " + code:12", hl.dsp.focus({ workspace = 3 })) -- Switch to Workspace 3
hl.bind(mainMod .. " + code:13", hl.dsp.focus({ workspace = 4 })) -- Switch to Workspace 4
hl.bind(mainMod .. " + code:14", hl.dsp.focus({ workspace = 5 })) -- Switch to Workspace 5
hl.bind(mainMod .. " + code:15", hl.dsp.focus({ workspace = 6 })) -- Switch to Workspace 6
hl.bind(mainMod .. " + code:16", hl.dsp.focus({ workspace = 7 })) -- Switch to Workspace 7
hl.bind(mainMod .. " + code:17", hl.dsp.focus({ workspace = 8 })) -- Switch to Workspace 8
hl.bind(mainMod .. " + code:18", hl.dsp.focus({ workspace = 9 })) -- Switch to Workspace 9
hl.bind(mainMod .. " + code:19", hl.dsp.focus({ workspace = 10 })) -- Switch to Workspace 10

hl.bind(mainMod .. " + SHIFT + code:10", hl.dsp.window.move({ workspace = 1 })) -- Move Window to Workspace 1
hl.bind(mainMod .. " + SHIFT + code:11", hl.dsp.window.move({ workspace = 2 })) -- Move Window to Workspace 2
hl.bind(mainMod .. " + SHIFT + code:12", hl.dsp.window.move({ workspace = 3 })) -- Move Window to Workspace 3
hl.bind(mainMod .. " + SHIFT + code:13", hl.dsp.window.move({ workspace = 4 })) -- Move Window to Workspace 4
hl.bind(mainMod .. " + SHIFT + code:14", hl.dsp.window.move({ workspace = 5 })) -- Move Window to Workspace 5
hl.bind(mainMod .. " + SHIFT + code:15", hl.dsp.window.move({ workspace = 6 })) -- Move Window to Workspace 6
hl.bind(mainMod .. " + SHIFT + code:16", hl.dsp.window.move({ workspace = 7 })) -- Move Window to Workspace 7
hl.bind(mainMod .. " + SHIFT + code:17", hl.dsp.window.move({ workspace = 8 })) -- Move Window to Workspace 8
hl.bind(mainMod .. " + SHIFT + code:18", hl.dsp.window.move({ workspace = 9 })) -- Move Window to Workspace 9
hl.bind(mainMod .. " + SHIFT + code:19", hl.dsp.window.move({ workspace = 10 })) -- Move Window to Workspace 10

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
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" })) -- Switch to Next Workspace
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" })) -- Switch to Previous Workspace
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag()) -- Drag Floating Window
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize()) -- Resize Floating Window
